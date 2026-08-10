#!/usr/bin/env python3
"""Chạy 1 hiệu ứng trong N giây để kiểm chứng riêng lẻ.

Cách dùng: python3 one_effect.py <tên_hiệu_ứng> [số_giây]
Tên xem trong effects.py (EFFECTS). "firmware" = test auto mode của controller.
"""
import sys
import time
from lamparray import LampArray
from effects import Effector, EFFECTS, EFFECT_SPEED

BASE_COLOR = (255, 90, 180)  # hồng — màu nền cho hiệu ứng dùng màu người dùng

if len(sys.argv) < 2:
    sys.exit("Cần tên hiệu ứng: " + ", ".join(EFFECTS) + " hoặc firmware")
name = sys.argv[1]
seconds = float(sys.argv[2]) if len(sys.argv) > 2 else 7.0

with LampArray() as la:
    if name == "firmware":
        print(f">>> TEST FIRMWARE AUTO MODE (0x46,0x01) — {seconds:.0f}s — đèn có TỰ chạy?")
        la._send([0x46, 0x01])
        time.sleep(seconds)
        la._send([0x46, 0x00])
    else:
        if name not in EFFECTS:
            sys.exit(f"Không có hiệu ứng '{name}'")
        speed = EFFECT_SPEED[name]
        eff = Effector(name, color=BASE_COLOR, intensity=255, speed_ms=speed)
        print(f">>> Hiệu ứng: {name} (speed={speed}ms) — {seconds:.0f}s")
        t0 = time.monotonic()
        while time.monotonic() - t0 < seconds:
            t_ms = int((time.monotonic() - t0) * 1000)
            r, g, b, i = eff.tick(t_ms)
            la.set_color(r, g, b, i)
            time.sleep(0.03)
    la.off()
    print("(đã tắt)")
