#!/usr/bin/env python3
"""GUI điều khiển đèn RGB bàn phím ASUS Vivobook S14 (M5406WA).

Nói chuyện trực tiếp với controller ITE5570 qua giao thức HID LampArray
(lamparray.py). Không cần chạy với quyền root nếu đã cài udev rule (setup.sh).

Cách dùng:
  python3 asus_rgb_gui.py            # mở GUI (tự áp dụng cấu hình đã lưu)
  python3 asus_rgb_gui.py --daemon   # chạy hiệu ứng nền, không GUI (autostart)
  python3 asus_rgb_gui.py --apply    # áp dụng màu tĩnh 1 lần rồi thoát
"""

from __future__ import annotations

import atexit
import json
import os
import subprocess
import sys
import time
import tkinter as tk
from tkinter import ttk

from lamparray import LampArray, LampArrayError, find_hidraw
from effects import Effector, EFFECTS

CONFIG_PATH = os.path.expanduser("~/.config/asus-kbd-rgb.json")
AUTOSTART_DIR = os.path.expanduser("~/.config/autostart")
AUTOSTART_FILE = os.path.join(AUTOSTART_DIR, "asus-kbd-rgb.desktop")
PIDFILE = os.path.expanduser("~/.config/asus-kbd-rgb.pid")

# Hiệu ứng cần vòng lặp liên tục (Tắt/Tĩnh chỉ ghi 1 lần là đủ)
ANIMATED = {e for e in EFFECTS if e not in ("Tắt", "Tĩnh")}

PRESETS = [
    ("Trắng",       (255, 255, 255)),
    ("Trắng ấm",    (255, 230, 200)),
    ("Đỏ",          (255, 40, 40)),
    ("Cam",         (255, 140, 30)),
    ("Vàng",        (255, 220, 60)),
    ("Xanh lá",     (60, 255, 90)),
    ("Xanh dương",  (40, 120, 255)),
    ("Xanh cyan",   (40, 255, 220)),
    ("Tím",         (160, 60, 255)),
    ("Hồng",        (255, 90, 180)),
]

DEFAULT = {"color": [255, 255, 255], "intensity": 255,
           "effect": "Tĩnh", "speed_ms": 80}


def load_config() -> dict:
    try:
        with open(CONFIG_PATH) as f:
            cfg = json.load(f)
        cfg.setdefault("color", DEFAULT["color"])
        cfg.setdefault("intensity", DEFAULT["intensity"])
        cfg.setdefault("effect", DEFAULT["effect"])
        cfg.setdefault("speed_ms", DEFAULT["speed_ms"])
        return cfg
    except (OSError, ValueError):
        return dict(DEFAULT)


def save_config(cfg: dict) -> None:
    os.makedirs(os.path.dirname(CONFIG_PATH), exist_ok=True)
    with open(CONFIG_PATH, "w") as f:
        json.dump(cfg, f, ensure_ascii=False, indent=2)


def toggle_autostart(enable: bool) -> None:
    os.makedirs(AUTOSTART_DIR, exist_ok=True)
    path = os.path.realpath(__file__)
    if enable:
        with open(AUTOSTART_FILE, "w") as f:
            f.write(
                "[Desktop Entry]\n"
                "Type=Application\n"
                f"Name=ASUS Keyboard RGB\n"
                f"Exec=python3 {path} --daemon\n"
                "X-GNOME-Autostart-enabled=true\n"
            )
    else:
        try:
            os.remove(AUTOSTART_FILE)
        except OSError:
            pass


def autostart_enabled() -> bool:
    return os.path.exists(AUTOSTART_FILE)


# ---------------------------------------------------------------- daemon ----

def _daemon_pid() -> int | None:
    """PID của daemon nền nếu đang chạy, ngược lại None."""
    try:
        with open(PIDFILE) as f:
            pid = int(f.read().strip())
        os.kill(pid, 0)
        return pid
    except (OSError, ValueError):
        return None


def _stop_daemon() -> None:
    pid = _daemon_pid()
    if pid is not None:
        try:
            os.kill(pid, 15)
        except OSError:
            pass
    try:
        os.remove(PIDFILE)
    except OSError:
        pass


def _start_daemon() -> None:
    """Chạy daemon nền áp hiệu ứng — để đèn tiếp tục sau khi đóng GUI."""
    if _daemon_pid() is not None:
        return
    devnull = open(os.devnull, "wb")
    subprocess.Popen(
        [sys.executable, os.path.realpath(__file__), "--daemon"],
        start_new_session=True, stdin=devnull, stdout=devnull, stderr=devnull,
    )


def _remove_pidfile() -> None:
    try:
        os.remove(PIDFILE)
    except OSError:
        pass


def apply_config_headless(cfg: dict) -> None:
    """Áp dụng cấu hình. Hiệu ứng động chạy vô hạn; Tắt/Tĩnh ghi 1 lần rồi thoát."""
    with LampArray() as la:
        eff = Effector(cfg["effect"], color=cfg["color"],
                       intensity=cfg["intensity"],
                       speed_ms=max(cfg["speed_ms"], 10))
        t0 = time.monotonic()
        while True:
            r, g, b, i = eff.tick(int((time.monotonic() - t0) * 1000))
            la.set_color(r, g, b, i)
            if cfg["effect"] in ("Tắt", "Tĩnh"):
                return
            time.sleep(eff.speed / 1000)


def daemon_main() -> None:
    """Chế độ nền: ghi pidfile rồi áp dụng cấu hình liên tục."""
    cfg = load_config()
    os.makedirs(os.path.dirname(PIDFILE), exist_ok=True)
    with open(PIDFILE, "w") as f:
        f.write(str(os.getpid()))
    atexit.register(_remove_pidfile)
    try:
        apply_config_headless(cfg)
    except (KeyboardInterrupt, LampArrayError) as e:
        print(f"Daemon dừng: {e}", file=sys.stderr)
        sys.exit(1)


class App:
    def __init__(self, root: tk.Tk):
        self.root = root
        self.la: LampArray | None = None
        self.lamp_count = 1
        self.min_interval_ms = 50
        self._after_id = None
        self._t0 = time.monotonic()

        root.title("Đèn bàn phím ASUS RGB")
        root.resizable(False, False)
        self._build()
        self._connect()
        self._load_ui()

    # ------------------------------------------------------------ UI ----
    def _build(self):
        f = ttk.Frame(self.root, padding=14)
        f.grid(sticky="nsew")

        # Status
        self.status = tk.StringVar(value="Đang tìm controller...")
        ttk.Label(f, textvariable=self.status, foreground="#555").grid(
            row=0, column=0, columnspan=3, sticky="w")

        # Preview + color sliders
        box = tk.Frame(f, width=64, height=64, highlightthickness=1,
                       highlightbackground="#bbb", bg="#ffffff")
        box.grid(row=1, column=2, rowspan=4, padx=(10, 0), pady=8)
        box.grid_propagate(False)
        self.preview = box

        self.rgb_var = [tk.IntVar(value=255), tk.IntVar(value=255), tk.IntVar(value=255)]
        self.hex_var = tk.StringVar(value="#ffffff")
        labels = ["Đỏ", "Xanh lá", "Xanh dương"]
        for i in range(3):
            ttk.Label(f, text=labels[i]).grid(row=2 + i, column=0, sticky="e", padx=(0, 6))
            s = ttk.Scale(f, from_=0, to=255, variable=self.rgb_var[i],
                          command=lambda _v, k=i: self._on_slider(k))
            s.grid(row=2 + i, column=1, sticky="ew", pady=2)
        f.columnconfigure(1, weight=1)

        ttk.Label(f, text="Hex").grid(row=5, column=0, sticky="e", padx=(0, 6))
        self.hex_entry = ttk.Entry(f, textvariable=self.hex_var, width=9)
        self.hex_entry.grid(row=5, column=1, sticky="w")
        self.hex_entry.bind("<Return>", self._on_hex)

        # Presets
        ttk.Label(f, text="Màu nhanh:").grid(row=6, column=0, sticky="e", padx=(0, 6))
        sw = ttk.Frame(f)
        sw.grid(row=6, column=1, columnspan=2, sticky="w", pady=6)
        for name, (r, g, b) in PRESETS:
            b_ = tk.Button(sw, text=name, width=8, relief="flat", fg="#222",
                           bg=f"#{r:02x}{g:02x}{b:02x}",
                           command=lambda rr=r, gg=g, bb=b: self._set_preset(rr, gg, bb))
            b_.pack(side="left", padx=2)

        # Brightness
        ttk.Label(f, text="Độ sáng").grid(row=7, column=0, sticky="e", padx=(0, 6))
        self.intensity_var = tk.IntVar(value=255)
        ttk.Scale(f, from_=0, to=255, variable=self.intensity_var,
                  command=lambda _v: None).grid(row=7, column=1, sticky="ew", pady=2)

        # Effect
        ttk.Label(f, text="Hiệu ứng").grid(row=8, column=0, sticky="e", padx=(0, 6))
        self.effect_var = tk.StringVar(value="Tĩnh")
        ttk.Combobox(f, textvariable=self.effect_var, values=EFFECTS,
                     state="readonly", width=14).grid(row=8, column=1, sticky="w")
        self.effect_var.trace_add("write", lambda *a: self._restart_effect())

        ttk.Label(f, text="Tốc độ").grid(row=9, column=0, sticky="e", padx=(0, 6))
        self.speed_var = tk.IntVar(value=80)
        ttk.Scale(f, from_=30, to=600, variable=self.speed_var,
                  command=lambda _v: self._restart_effect()).grid(
            row=9, column=1, sticky="ew", pady=2)

        # Actions
        btns = ttk.Frame(f)
        btns.grid(row=10, column=0, columnspan=3, sticky="ew", pady=(12, 0))
        ttk.Button(btns, text="Áp dụng", command=self._apply).pack(side="left")
        ttk.Button(btns, text="Tắt đèn", command=self._turn_off).pack(side="left", padx=6)
        ttk.Button(btns, text="Lưu mặc định", command=self._save_default).pack(side="left")
        self.autostart_var = tk.BooleanVar(value=autostart_enabled())
        ttk.Checkbutton(btns, text="Tự áp dụng khi đăng nhập",
                        variable=self.autostart_var,
                        command=self._on_autostart).pack(side="right")

    # ------------------------------------------------------- logic ----
    def _connect(self):
        try:
            path = find_hidraw()
            self.la = LampArray(path)
            attrs = self.la.attributes()
            self.lamp_count = max(attrs["lamp_count"], 1)
            self.min_interval_ms = max(attrs["min_interval_us"] // 1000, 10)
            self.status.set(f"Đã kết nối {path} — {self.lamp_count} vùng đèn, "
                            f"chu kỳ tối thiểu {self.min_interval_ms} ms")
        except LampArrayError as e:
            self.la = None
            self.status.set(str(e))

    def _load_ui(self):
        cfg = load_config()
        for i, v in enumerate(cfg["color"]):
            self.rgb_var[i].set(v)
        self.intensity_var.set(cfg["intensity"])
        self.effect_var.set(cfg["effect"])
        self.speed_var.set(cfg["speed_ms"])
        self._sync_preview()
        self._restart_effect()  # tự áp dụng cấu hình đã lưu (đúng tốc độ)

    # ---------------------------------------------------- callbacks ----
    def _on_slider(self, _k=None):
        self._sync_preview()

    def _on_hex(self, _e=None):
        h = self.hex_var.get().strip().lstrip("#")
        if len(h) == 6:
            try:
                r, g, b = int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16)
            except ValueError:
                return
            self.rgb_var[0].set(r); self.rgb_var[1].set(g); self.rgb_var[2].set(b)
            self._sync_preview()

    def _set_preset(self, r, g, b):
        self.rgb_var[0].set(r); self.rgb_var[1].set(g); self.rgb_var[2].set(b)
        self._sync_preview()

    def _sync_preview(self):
        r, g, b = self._rgb()
        self.hex_var.set(f"#{r:02x}{g:02x}{b:02x}")
        self.preview.configure(bg=f"#{r:02x}{g:02x}{b:02x}")

    def _rgb(self):
        return (self.rgb_var[0].get(), self.rgb_var[1].get(), self.rgb_var[2].get())

    def _apply(self):
        self._save_default()
        self._restart_effect()

    def _save_default(self):
        cfg = dict(DEFAULT)
        cfg["color"] = list(self._rgb())
        cfg["intensity"] = self.intensity_var.get()
        cfg["effect"] = self.effect_var.get()
        cfg["speed_ms"] = self.speed_var.get()
        save_config(cfg)

    def _turn_off(self):
        self.effect_var.set("Tắt")
        if self.la:
            try:
                self.la.off()
            except OSError as e:
                self.status.set(f"Lỗi: {e}")

    def _on_autostart(self):
        toggle_autostart(self.autostart_var.get())

    # ------------------------------------------------------ effects ----
    def _restart_effect(self):
        _stop_daemon()  # GUI đảm nhận → tắt daemon nền nếu có
        if self._after_id:
            self.root.after_cancel(self._after_id)
            self._after_id = None
        self._t0 = time.monotonic()
        self._eff = Effector(
            self.effect_var.get(),
            color=self._rgb(),
            intensity=self.intensity_var.get(),
            speed_ms=max(self.speed_var.get(), self.min_interval_ms),
        )
        self._tick()

    def _tick(self):
        self._after_id = None
        if self.la is None:
            return
        if self.effect_var.get() == "Tắt":
            self._send(0, 0, 0, 0)
            return
        t_ms = int((time.monotonic() - self._t0) * 1000)
        r, g, b, i = self._eff.tick(t_ms)
        self._send(r, g, b, i)
        self._after_id = self.root.after(self._eff.speed, self._tick)

    def _send(self, r, g, b, intensity):
        try:
            self.la.set_color(r, g, b, intensity)
        except OSError as e:
            self.status.set(f"Lỗi ghi thiết bị: {e}")
            self.la = None

    def on_close(self):
        if self._after_id:
            self.root.after_cancel(self._after_id)
        self._save_default()  # lưu trạng thái đang chọn để không mất khi đóng app
        if self.effect_var.get() in ANIMATED:
            _start_daemon()  # hiệu ứng chạy tiếp ở nền sau khi đóng GUI
        else:
            _stop_daemon()   # Tắt/Tĩnh: màu đã nằm trên phần cứng, không cần daemon
        self.root.destroy()


def main():
    if "--daemon" in sys.argv:
        daemon_main()
        return
    if "--apply" in sys.argv:
        _stop_daemon()
        cfg = load_config()
        try:
            with LampArray() as la:
                la.set_color(*cfg["color"], cfg["intensity"])
            print("Đã áp dụng màu tĩnh.")
        except LampArrayError as e:
            print(f"Không áp dụng được: {e}", file=sys.stderr)
            sys.exit(1)
        return
    root = tk.Tk()
    app = App(root)
    root.protocol("WM_DELETE_WINDOW", app.on_close)
    root.mainloop()


if __name__ == "__main__":
    main()
