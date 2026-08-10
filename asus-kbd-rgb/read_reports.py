#!/usr/bin/env python3
"""Đọc các feature report để soi giao diện màu thật (chuẩn + vendor 0xFF59)."""
from lamparray import LampArray


def show(name, buf):
    print(f"{name}: {list(buf)}")


with LampArray() as la:
    for rid, size in [(0x41, 23), (0x45, 10), (0x46, 3), (0x31, 23), (0x32, 8)]:
        try:
            buf = la._feature_report(rid, size)
            show(f"report 0x{rid:02x} ({size}B)", buf)
        except OSError as e:
            print(f"report 0x{rid:02x} ({size}B): LỖI {e}")
        except Exception as e:
            print(f"report 0x{rid:02x} ({size}B): {type(e).__name__} {e}")
