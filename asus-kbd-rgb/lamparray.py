#!/usr/bin/env python3
"""Core HID LampArray driver for the ASUS Vivobook S14 (M5406WA) RGB keyboard.

The RGB backlight of this laptop is NOT controlled via WMI/ACPI. It is an
ITE5570 HID controller (vendor 0B05, product 5570) speaking the standard
USB HID LampArray protocol (usage page 0x59) -- the same protocol Windows
Dynamic Lighting uses. We talk to it directly through /dev/hidraw.

No kernel patches, no root needed once a udev rule grants access to hidraw.

Protocol references (feature reports):
  0x41  Lamp Array Attributes   (23 bytes)
  0x45  Set Lamp Color          [0x45, count, start<H>, end<H>, (r,g,b,intensity)*count]
  0x46  Set Autonomous Mode     [0x46, 0|1]
"""

from __future__ import annotations

import array
import fcntl
import glob
import struct
from typing import Optional

VENDOR_ID = "0B05"
PRODUCT_ID = "5570"

# HIDIOCSFEATURE / HIDIOCGFEATURE (linux/hidraw.h)
HIDIOCSFEATURE = 0xC0084806  # _IOWR('H', 0x06, size) -- base for size 0
HIDIOCGFEATURE = 0xC0084807  # _IOWR('H', 0x07, size)

ATTR_REPORT_ID = 0x41
SET_COLOR_REPORT_ID = 0x45
AUTONOMOUS_REPORT_ID = 0x46


def _iowr(nr: int, size: int) -> int:
    # _IOWR(type='H'=0x48, nr, size): dir(2)<<30 | size<<16 | type<<8 | nr
    return 0xC0000000 | (size << 16) | (0x48 << 8) | nr


def find_hidraw() -> Optional[str]:
    """Locate the hidraw device backing the ITE5570 controller."""
    for uevent in glob.glob("/sys/class/hidraw/hidraw*/device/uevent"):
        try:
            with open(uevent) as f:
                content = f.read()
        except OSError:
            continue
        if f"0000{VENDOR_ID}:0000{PRODUCT_ID}" in content.upper():
            return "/dev/" + uevent.split("/")[4]
    return None


class LampArrayError(RuntimeError):
    pass


class LampArray:
    """Minimal LampArray client over a hidraw device."""

    def __init__(self, path: Optional[str] = None):
        self.path = path or find_hidraw()
        if not self.path:
            raise LampArrayError(
                f"Không tìm thấy controller đèn bàn phím (ITE5570 {VENDOR_ID}:{PRODUCT_ID}). "
                "Chỉ hoạt động trên ASUS Vivobook có đèn RGB."
            )
        try:
            self._fd = open(self.path, "rb+", buffering=0)
        except OSError as e:
            raise LampArrayError(
                f"Không mở được {self.path}: {e}\n"
                "Cần udev rule (xem setup.sh) hoặc chạy với sudo."
            ) from e
        self._lamp_end: Optional[int] = None

    def close(self) -> None:
        try:
            self._fd.close()
        except Exception:
            pass

    def __enter__(self) -> "LampArray":
        return self

    def __exit__(self, *exc) -> None:
        self.close()

    # -- low level ------------------------------------------------------
    def _feature_report(self, report_id: int, size: int) -> array.array:
        buf = array.array("B", [report_id] + [0] * (size - 1))
        fcntl.ioctl(self._fd, _iowr(HIDIOCGFEATURE & 0xFF, size), buf)
        return buf

    def _send(self, data: list[int]) -> None:
        buf = array.array("B", data)
        fcntl.ioctl(self._fd, _iowr(HIDIOCSFEATURE & 0xFF, len(data)), buf)

    # -- high level -----------------------------------------------------
    def attributes(self) -> dict:
        """Read Lamp Array Attributes (report 0x41)."""
        report = self._feature_report(ATTR_REPORT_ID, 23)
        lamp_count = struct.unpack_from("<H", report, 1)[0]
        bbox_w, bbox_h, bbox_d, kind, min_interval_us = struct.unpack_from(
            "<IIIII", report, 3
        )
        return {
            "lamp_count": lamp_count,
            "bbox_width": bbox_w,
            "bbox_height": bbox_h,
            "bbox_depth": bbox_d,
            "kind": kind,
            "min_interval_us": min_interval_us,
        }

    def set_color(self, r: int, g: int, b: int, intensity: int = 255,
                  start: int = 0, end: int = -1) -> None:
        """Set a solid color over the lamp range [start..end] (default: all lamps).

        Bắt buộc gửi host-mode (report 0x46, ĐÚNG 2 byte) trước mỗi lệnh màu:
        nếu gửi 3 byte (kèm duration) firmware không vào host mode và luôn
        render trắng bất kể byte màu (đã test trên M5406WA).
        """
        self._send([AUTONOMOUS_REPORT_ID, 0x00])  # host mode, 2 byte
        if end < 0:
            if self._lamp_end is None:
                attrs = self.attributes()
                self._lamp_end = max(attrs["lamp_count"] - 1, 0)
            end = self._lamp_end
        data = [SET_COLOR_REPORT_ID, 0x01]
        data += list(struct.pack("<H", start))
        data += list(struct.pack("<H", end))
        data += [r & 0xFF, g & 0xFF, b & 0xFF, intensity & 0xFF]
        self._send(data)

    def set_autonomous(self, enabled: bool) -> None:
        """Chuyển controller sang firmware mode (tự chạy animation) — 2 byte."""
        self._send([AUTONOMOUS_REPORT_ID, 1 if enabled else 0])

    def off(self) -> None:
        self.set_color(0, 0, 0, 0)


if __name__ == "__main__":
    import sys

    path = find_hidraw()
    print(f"hidraw: {path}")
    if not path:
        sys.exit(1)
    with LampArray(path) as la:
        attrs = la.attributes()
        print(f"lamp_count={attrs['lamp_count']} min_interval={attrs['min_interval_us']}us")
        la.set_color(255, 255, 255, 255)
        print("Đã đặt đèn trắng 100%. Bấm Ctrl+C để tắt...")
        try:
            import time
            time.sleep(5)
        except KeyboardInterrupt:
            pass
        la.off()
        print("Đã tắt đèn.")
