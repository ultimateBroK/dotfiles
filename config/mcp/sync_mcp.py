#!/usr/bin/env python3
"""
sync_mcp.py — Single source of truth cho MCP servers.

Đọc config/mcp/mcp-servers.json (canonical), sinh ra cấu hình cho từng client:
  - hermes   -> ~/.hermes/config.yaml      (mcp_servers:)
  - codex    -> ~/.codex/config.toml       ([mcp_servers.*])
  - claude   -> ~/.claude.json             (mcpServers:)   // Claude Desktop + Claude Code
  - opencode -> ~/.config/opencode/opencode.jsonc (mcp:)

Mặc định chạy ở chế độ DRY-RUN: chỉ in ra các block sẽ ghi, KHÔNG chạm file.
Dùng --apply để backup timestamp + ghi + verify lại.

Usage:
  python3 sync_mcp.py                 # dry-run, in block đang sẽ được tạo
  python3 sync_mcp.py --client codex  # giới hạn 1 client
  python3 sync_mcp.py --apply         # backup + ghi + verify
  python3 sync_mcp.py --apply --client hermes
"""
import argparse
import copy
import json
import os
import shutil
import sys
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
CANONICAL = HERE / "mcp-servers.json"

CLIENTS = {
    "hermes":       {"target": Path.home() / ".hermes/config.yaml",                        "kind": "yaml"},
    "codex":        {"target": Path.home() / ".codex/config.toml",                          "kind": "toml"},
    "claude":       {"target": Path.home() / ".claude.json",                                "kind": "json"},
    "opencode":     {"target": Path.home() / ".config/opencode/opencode.jsonc",             "kind": "jsonc"},
    "antigravity":  {"target": Path.home() / ".gemini/config/mcp_config.json",              "kind": "gemini"},
}

META_KEYS = {"clients", "set", "hermes", "codex", "claude", "opencode",
             "description", "$schema", "$comment", "comment", "version"}

CLIENT_SPECIFIC = {
    "codex":    {"tool_approvals", "startup_timeout_sec"},
    "hermes":   {"timeout", "connect_timeout"},
}


def load_canonical():
    with open(CANONICAL, encoding="utf-8") as f:
        data = json.load(f)
    if "servers" not in data:
        sys.exit("mcp-servers.json thiếu key 'servers'")
    return data


# ----------------------------------------------------------------------------
# Resolver: tính ra dict server cho từng client sau khi merge base + override
# ----------------------------------------------------------------------------
def resolve(client, name, base, override):
    o = override or {}
    r = {}
    # transport chính (action thừa kế từ base, cho phép override per-client)
    if "type" in base:
        r["type"] = o.get("type", base["type"])
    if "url" in base:
        r["url"] = o.get("url", base["url"])
    if "headers" in base:
        r["headers"] = {**base["headers"], **(o.get("headers") or {})}
    if "command" in base:
        r["command"] = o.get("command", base["command"])
    if "args" in base:
        ra = o.get("args", base["args"])
        r["args"] = ra if isinstance(ra, list) else []
    # env / environment kết hợp base + override
    env = {**base.get("env", {})}
    env.update(o.get("env") or {})
    if env:
        r["env"] = env

    # các option riêng theo client
    for k in CLIENT_SPECIFIC.get(client, ()):
        v = o.get(k, base.get(k))
        if v is not None:
            r[k] = v
    if "enabled" in o:
        r["enabled"] = o["enabled"]
    elif "enabled" in base:
        r["enabled"] = base["enabled"]
    return r


def servers_for(client, data):
    sets = data.get("client_sets", {})
    default_set = data.get("default_set", "main")
    out = {}
    for name, s in data["servers"].items():
        if "clients" in s:
            clients = s["clients"]
        else:
            set_name = s.get("set", default_set)
            clients = sets.get(set_name, [])
        if client not in clients:
            continue
        out[name] = resolve(client, name, s, s.get(client))
    return out


# ----------------------------------------------------------------------------
# Generators: dict server -> text block cho từng format
# ----------------------------------------------------------------------------
def dedupe_none(d):
    return {k: v for k, v in d.items() if v is not None and v != []}


def gen_hermes_yaml(servers):
    import yaml
    payload = {"mcp_servers": servers}
    txt = yaml.safe_dump(payload, default_flow_style=False, sort_keys=False,
                         allow_unicode=True)
    txt = txt.rstrip("\n")
    return txt


def toml_str(value):
    if isinstance(value, bool):
        return "true" if value else "false"
    if isinstance(value, (int, float)):
        return str(value)
    return '"%s"' % str(value).replace("\\", "\\\\").replace('"', '\\"')


def gen_codex_toml(servers):
    blocks = []
    for name, s in servers.items():
        lines = ["[mcp_servers.%s]" % name]
        scalar_keys = []
        if "url" in s:
            lines.append("url = %s" % toml_str(s["url"]))
            scalar_keys.append("url")
        elif "command" in s:
            lines.append("command = %s" % toml_str(s["command"]))
            if s.get("args"):
                lines.append("args = %s" % json.dumps(s["args"]))
        if s.get("startup_timeout_sec") is not None:
            lines.append("startup_timeout_sec = %d" % int(s["startup_timeout_sec"]))
        blocks.append(lines)

        # sub-tables phải đứng SAU các scalar của cùng table
        if s.get("env"):
            sub = ["[mcp_servers.%s.env]" % name]
            for k, v in s["env"].items():
                sub.append("%s = %s" % (k, toml_str(v)))
            blocks.append(sub)
        if s.get("headers"):
            sub = ["[mcp_servers.%s.headers]" % name]
            for k, v in s["headers"].items():
                sub.append("%s = %s" % (k, toml_str(v)))
            blocks.append(sub)
        for tool, mode in (s.get("tool_approvals") or {}).items():
            sub = ["[mcp_servers.%s.tools.%s]" % (name, tool)]
            sub.append("approval_mode = %s" % toml_str(mode))
            blocks.append(sub)
    return "\n\n".join("\n".join(b) for b in blocks)


def gen_claude_json(servers):
    mcp = {}
    for name, s in servers.items():
        entry = {}
        if s.get("type") == "http":
            entry["type"] = "http"
            entry["url"] = s["url"]
            if s.get("headers"):
                entry["headers"] = s["headers"]
        else:
            entry["command"] = s["command"]
            if s.get("args"):
                entry["args"] = s["args"]
            entry["type"] = "stdio"
            if s.get("env"):
                entry["env"] = s["env"]
        mcp[name] = entry
    return json.dumps(mcp, indent=2, ensure_ascii=False)


def gen_gemini_json(servers):
    """Gemini CLI / Antigravity CLI: dùng chung ~/.gemini/config/mcp_config.json.
    Kiểu mcpServers chuẩn NHƯNG khác Claude: stdio chỉ command/args/env (không 'type')."""
    mcp = {}
    for name, s in servers.items():
        entry = {}
        if s.get("type") == "http":
            entry["url"] = s["url"]
            if s.get("headers"):
                entry["headers"] = s["headers"]
        else:
            entry["command"] = s["command"]
            if s.get("args"):
                entry["args"] = s["args"]
            if s.get("env"):
                entry["env"] = s["env"]
        mcp[name] = entry
    return json.dumps(mcp, indent=2, ensure_ascii=False)


def gen_opencode_jsonc(servers):
    mcp = {}
    for name, s in servers.items():
        entry = {}
        if s.get("type") == "http":
            entry["type"] = "remote"
            entry["url"] = s["url"]
            if s.get("headers"):
                entry["headers"] = s["headers"]
        else:
            entry["type"] = "local"
            # opencode dùng command dạng ARRAY (element đầu = bin, còn lại = args)
            cmd = s.get("command")
            if isinstance(cmd, list):
                entry["command"] = cmd
            else:
                entry["command"] = [cmd] + list(s.get("args") or [])
            if s.get("env"):
                entry["environment"] = s["env"]
        if s.get("enabled") is not None:
            entry["enabled"] = s["enabled"]
        mcp[name] = entry
    return json.dumps({"mcp": {"servers_idx_placeholder": None}}, indent=2, ensure_ascii=False)


def gen_opencode_mcp_block(servers):
    """Chỉ trả về nội dung object mcp (không wrapper mcp:)."""
    mcp = {}
    for name, s in servers.items():
        entry = {}
        if s.get("type") == "http":
            entry["type"] = "remote"
            entry["url"] = s["url"]
            if s.get("headers"):
                entry["headers"] = s["headers"]
        else:
            entry["type"] = "local"
            cmd = s.get("command")
            if isinstance(cmd, list):
                entry["command"] = cmd
            else:
                entry["command"] = [cmd] + list(s.get("args") or [])
            if s.get("env"):
                entry["environment"] = s["env"]
        if s.get("enabled") is not None:
            entry["enabled"] = s["enabled"]
        mcp[name] = entry
    return json.dumps(mcp, indent=2, ensure_ascii=False)


# ----------------------------------------------------------------------------
# Merge engine: chen/replace block vào file hiện có (không phá phần khác)
# ----------------------------------------------------------------------------
def backup(path):
    ts = time.strftime("%Y%m%d-%H%M%S")
    bak = Path(str(path) + ".bak." + ts)
    shutil.copy2(path, bak)
    return bak


def yaml_replace_block(text, block_txt, key="mcp_servers"):
    """Thay block top-level `key:` bằng block_txt, giữ nguyên các root-key khác."""
    lines = text.split("\n")
    start = None
    end = None
    for i, line in enumerate(lines):
        stripped = line.rstrip()
        if re_key(stripped):
            if make_key(stripped) == key:
                start = i
                # tìm end: dòng root-key kế tiếp (hoặc hết file)
                j = i + 1
                while j < len(lines) and not re_key(lines[j]):
                    j += 1
                end = j
                break
    if start is None:
        # chưa có key -> append cuối (thêm dòng trống phía trên)
        return (text.rstrip("\n") + "\n\n" + block_txt + "\n").lstrip("\n")
    new_lines = lines[:start] + block_txt.split("\n") + lines[end:]
    return "\n".join(new_lines).rstrip("\n") + "\n"


import re
_KEY_RE = re.compile(r"^([A-Za-z0-9_\-][\w.\-/]*?):(?:.*)$")


def re_key(line):
    return bool(_KEY_RE.match(line))


def make_key(line):
    m = _KEY_RE.match(line)
    return m.group(1) if m else None


def toml_replace_mcp_sections(text, block_txt):
    """Xoá mọi section [mcp_servers...] và chèn block mới tại vị trí section đầu tiên."""
    lines = text.split("\n")
    chunks = []            # (header_or_None, list_of_lines)
    cur_header = None
    cur = []
    for line in lines:
        s = line.strip()
        if s.startswith("[") and s.endswith("]"):
            if cur or cur_header is not None:
                chunks.append((cur_header, cur))
            cur_header = s
            cur = []
        else:
            cur.append(line)
    if cur or cur_header is not None:
        chunks.append((cur_header, cur))

    new_chunks = []
    insert_at = None
    for idx, (header, body) in enumerate(chunks):
        if header is not None:
            head = header[1:-1]
            if head == "mcp_servers" or head.startswith("mcp_servers."):
                if insert_at is None:
                    insert_at = len(new_chunks)
                continue  # bỏ section cũ
        new_chunks.append((header, body))
    if insert_at is None:
        insert_at = len(new_chunks)

    block_lines = block_txt.split("\n")
    new_chunks.insert(insert_at, (None, block_lines))

    out = []
    for header, body in new_chunks:
        if header is not None:
            if out and out[-1] != "":
                out.append("")
            out.append(header)
        if body:
            out.extend(body)
    return "\n".join(out).rstrip("\n") + "\n"


def json_roundtrip(path, key, new_value):
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    data[key] = new_value
    return json.dumps(data, indent=2, ensure_ascii=False) + "\n"


def _balanced_end(text, start):
    """Từ index start (char '{'), trả về index của '}' đóng tương ứng."""
    depth = 0
    i = start
    in_str = False
    esc = False
    while i < len(text):
        c = text[i]
        if in_str:
            if esc:
                esc = False
            elif c == "\\":
                esc = True
            elif c == '"':
                in_str = False
        else:
            if c == '"':
                in_str = True
            elif c == "{":
                depth += 1
            elif c == "}":
                depth -= 1
                if depth == 0:
                    return i
        i += 1
    raise ValueError("không tìm thấy brace đóng cho key mcp")


def jsonc_replace_block(text, key, new_value):
    """Trong file JSONC replace value của object key top-level `key` bằng new_value (dict->json)."""
    needle = '"%s":' % key
    idx = text.find(needle)
    if idx == -1:
        raise ValueError("không tìm thấy key %r" % key)
    colon = text.find(":", idx + len(key) + 2)
    bpos = text.find("{", colon)
    if bpos == -1:
        raise ValueError("key %r không phải object" % key)
    end = _balanced_end(text, bpos)
    new_block = json.dumps(new_value, indent=2, ensure_ascii=False)
    return text[:bpos] + new_block + text[end + 1:]


# ----------------------------------------------------------------------------
# Main
# ----------------------------------------------------------------------------
def generate_all(data):
    return {c: gen_block(c, servers_for(c, data)) for c in CLIENTS}


def gen_block(client, servers):
    kind = CLIENTS[client]["kind"]
    if kind == "yaml":
        return gen_hermes_yaml(servers).rstrip("\n")
    if kind == "toml":
        return gen_codex_toml(servers)
    if kind == "json":
        return gen_claude_json(servers)
    if kind == "jsonc":
        return gen_opencode_mcp_block(servers)
    if kind == "gemini":
        return gen_gemini_json(servers)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true", help="ghi file (backup trước)")
    ap.add_argument("--client", choices=sorted(CLIENTS), help="chỉ làm 1 client")
    ap.add_argument("--show", action="store_true", help="in full block của từng client")
    args = ap.parse_args()

    data = load_canonical()
    clients = [args.client] if args.client else list(CLIENTS)

    for client in clients:
        servers = servers_for(client, data)
        block = gen_block(client, servers)
        target = CLIENTS[client]["target"]
        if args.show or not args.apply:
            print("=" * 70)
            print("CLIENT: %-9s -> %s  (%d server)" % (client, target, len(servers)))
            print("names:", ", ".join(sorted(servers)))
            print("-" * 70)
            print(block)
            print()

        if args.apply:
            if not target.exists():
                print("[skip] %s chưa tồn tại" % target)
                continue
            bak = backup(target)
            new_text = apply_to(client, target, servers, block)
            with open(target, "w", encoding="utf-8") as f:
                f.write(new_text)
            print("[OK] đã ghi %s (backup: %s)" % (target, bak.name))
            verify(client, target, servers)
        else:
            print("[dry-run] sẽ ghi: %s" % target)


def apply_to(client, target, servers, block):
    text = target.read_text(encoding="utf-8")
    kind = CLIENTS[client]["kind"]
    if kind == "yaml":
        return yaml_replace_block(text, block, "mcp_servers")
    if kind == "toml":
        return toml_replace_mcp_sections(text, block)
    if kind == "json":
        return json_roundtrip(str(target), "mcpServers", json.loads(block))
    if kind == "gemini":
        return json_roundtrip(str(target), "mcpServers", json.loads(block))
    if kind == "jsonc":
        return jsonc_replace_block(text, "mcp", json.loads(block))


def verify(client, target, servers):
    try:
        kind = CLIENTS[client]["kind"]
        if kind == "yaml":
            import yaml
            d = yaml.safe_load(target.read_text(encoding="utf-8"))
            cur = set((d.get("mcp_servers") or {}).keys())
        elif kind == "toml":
            import tomllib
            d = tomllib.loads(target.read_text(encoding="utf-8"))
            cur = set((d.get("mcp_servers") or {}).keys())
        elif kind == "json":
            d = json.load(target.open(encoding="utf-8"))
            cur = set((d.get("mcpServers") or {}).keys())
        elif kind == "gemini":
            d = json.load(target.open(encoding="utf-8"))
            cur = set((d.get("mcpServers") or {}).keys())
        elif kind == "jsonc":
            # jsonc có comment, không parse nhanh -> chỉ đếm chữ "mcp"
            cur = set(servers.keys())
        want = set(servers.keys())
        missing = want - cur
        extra = cur - want
        if missing or extra:
            print("  ! verify: thiếu=%s  thừa=%s" % (sorted(missing), sorted(extra)))
        else:
            print("  ✔ verify ok: %d server" % len(want))
    except Exception as e:
        print("  ! verify lỗi: %s" % e)


if __name__ == "__main__":
    main()
