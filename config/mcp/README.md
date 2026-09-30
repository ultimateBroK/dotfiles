# MCP — Single Source of Truth (ssot)

Quản lý **toàn bộ MCP server** cho 5 client từ **1 file**: `mcp-servers.json`.

- **hermes**   → `~/.hermes/config.yaml`               (`mcp_servers:`)
- **codex**    → `~/.codex/config.toml`                (`[mcp_servers.*]`)
- **claude**   → `~/.claude.json`                      (`mcpServers:`)  *Claude Desktop + Claude Code*
- **opencode** → `~/.config/opencode/opencode.jsonc`   (`mcp:`)
- **antigravity** → `~/.gemini/config/mcp_config.json` (`mcpServers:`)  *Antigravity CLI + Gemini CLI dùng chung file này*

## Cách dùng

```bash
cd ~/Downloads/dotfiles/config/mcp

./sync-mcp.sh                 # dry-run: in block sẽ tạo, KHÔNG ghi file
./sync-mcp.sh --apply         # backup *.bak.<ts> rồi ghi + tự verify
./sync-mcp.sh --client codex  # chỉ đồng bộ 1 client
```

**Muốn thêm / sửa server:** mở `mcp-servers.json`, sửa, chạy `./sync-mcp.sh --apply`.

## Cấu trúc file nguồn

```jsonc
{
  "client_sets": {                       // NHÓM client đặt tên — định nghĩa 1 lần
    "main":  ["hermes", "codex", "opencode"],
    "all":   ["hermes", "codex", "claude", "opencode"]
  },
  "default_set": "main",
  "servers": {
    "ten-server": {
      "command": "uvx",                 // stdio
      "args": ["mcp-server-analyzer"],  // stdio
      // HOẶC (http):  "type": "http", "url": "https://...", "headers": {...},
      "env": { "API_KEY": "..." },      // stdio env
      "set": "main",                    // áp dụng cho nhóm này (bỏ đi = nhóm default_set)
      // override riêng từng client:
      "codex":   { "tool_approvals": {"fetch":"approve"} },
      "hermes":  { "timeout": 120, "connect_timeout": 60 }
    }
  }
}
```

- Nhóm client (`client_sets`) khai **một lần**; mỗi server chỉ ghi `"set": "<nhóm>"`.
  Bỏ `set` → dùng `default_set` (mặc định `main`).
- Muốn một server chạy ở đâu → **sửa `set`**; muốn đổi hàng loạt → sửa `client_sets` ở đầu file.
  Không còn gõ `clients: [...]` thủ công cho từng server.
- **`set: "none"`** = tắt server đó (giữ định nghĩa nhưng không ghi vào client nào) — dùng khi server
  tạm chết (thiếu license / chưa cài) mà muốn các client vẫn khởi động sạch.
- Mỗi client có thể override riêng bằng key `hermes` / `codex` / `claude` / `opencode`.
- *(Tương thích ngược:* nếu một server vẫn dùng `"clients": [...]` thì ưu tiên theo đó.)*

## Lưu ý

- **`mcp-servers.json` chứa API key → đã gitignore** (không bao giờ commit lên GitHub).
  `mcp-servers.example.json` (không secret) là bản mẫu để commit.
- **Đổi tên cũ → mới:** `taivly-mcp` (Hermes cũ) → **`tavily-mcp`** (thống nhất), và đổi
  command từ `npx tavily-mcp@latest` sang binary `/home/ultimatebrok/.npm-global/bin/tavily-mcp`.
  → Tiền tố tool của Hermes đổi từ `mcp_taivly_mcp_*` → `mcp_tavily_mcp_*`.
- **Cần restart client** để nhận config mới:
  - Hermes: mở phiên mới (`hermes`) hoặc `/reset`.
  - Codex: thoát + mở lại.
  - Claude Code / Desktop: mở lại.
  - OpenCode: mở lại.
- Backup cũ nằm cạnh file (`*.bak.<ts>`); xoá được sau khi đã ổn.

## Custom mcp cho các client khác (Cursor, Windsurf, VS Code...)

`sync_mcp.py` hiện hỗ trợ 4 client trên. Nếu cần thêm client, thêm entry mới vào
`CLIENTS` (định nghĩa `kind` + hàm `gen_*`) — xem đầu file `sync_mcp.py`.
