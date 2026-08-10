#!/usr/bin/env python3
"""Thí nghiệm: tắt đèn trắng phần cứng, rồi đặt màu qua LampArray."""
import time
import sys
from lamparray import LampArray

with LampArray() as la:
    # Tắt autonomous mode (theo descriptor: [0x46, autonomous, duration])
    la._send([0x46, 0x00, 0x00])
    print("autonomous OFF")
    for name, rgb in [
        ("ĐỎ", (255, 0, 0)),
        ("XANH LÁ", (0, 255, 0)),
        ("XANH DƯƠNG", (0, 0, 255)),
        ("TRẮNG", (255, 255, 255)),
    ]:
        la.set_color(*rgb, 255)
        print(f"-> {name} 5s")
        time.sleep(5)
    la.off()
    print("Đã tắt.")
