#!/usr/bin/env python3
"""Demo nhanh: quét qua các màu cơ bản để kiểm tra đèn RGB."""
import time
from lamparray import LampArray

COLORS = [
    ("Đỏ", 255, 40, 40),
    ("Xanh lá", 60, 255, 90),
    ("Xanh dương", 40, 120, 255),
    ("Vàng", 255, 220, 60),
    ("Tím", 160, 60, 255),
    ("Trắng", 255, 255, 255),
]

with LampArray() as la:
    for name, r, g, b in COLORS:
        la.set_color(r, g, b, 255)
        print(f"-> {name} ({r},{g},{b})")
        time.sleep(1.5)
    # cầu vồng nhanh
    print("-> Cầu vồng quét 4s...")
    import colorsys
    t0 = time.time()
    while time.time() - t0 < 4:
        h = ((time.time() - t0) / 4) % 1.0
        r, g, b = colorsys.hsv_to_rgb(h, 1.0, 1.0)
        la.set_color(int(r * 255), int(g * 255), int(b * 255), 255)
        time.sleep(0.02)
    la.off()
    print("Đã tắt đèn.")
