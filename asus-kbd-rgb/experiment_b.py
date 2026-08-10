#!/usr/bin/env python3
"""Test giao diện vendor 0xFF59: ghi màu qua report 0x32 + đọc lại."""
import time
from lamparray import LampArray

with LampArray() as la:
    for name, rgb in [("ĐỎ", (255, 0, 0)), ("XANH LÁ", (0, 255, 0)), ("XANH DƯƠNG", (0, 0, 255))]:
        # [0x32, lamp_id(16-bit little), r, g, b, intensity]
        data = [0x32, 0x00, 0x00] + list(rgb) + [255]
        la._send(data)
        print(f"-> GHI 0x32 {name}: {data}")
        time.sleep(0.3)
        buf = la._feature_report(0x32, 8)
        print(f"   ĐỌC LẠI 0x32: {list(buf)}")
        time.sleep(3.5)
    la.off()
    print("Đã tắt.")
