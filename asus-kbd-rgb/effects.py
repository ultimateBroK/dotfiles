#!/usr/bin/env python3
"""Engine hiệu ứng đèn bàn phím ASUS M5406WA (1 vùng RGB).

Mọi hiệu ứng đều chạy BẰNG PHẦN MỀM (gửi màu liên tục qua 0x45) vì firmware
của controller ITE5570 (0x5570) không có animation sẵn. Vì đèn chỉ 1 vùng,
hiệu ứng là biến đổi theo THỜI GIAN: màu, độ sáng, tần số nhấp nháy.

Mỗi hiệu ứng = hàm (t_ms, self) -> (r, g, b, intensity).
"""

from __future__ import annotations

import colorsys
import math
import random

EFFECTS = [
    "Tắt",
    "Tĩnh",
    "Thở",
    "Xung",
    "Strobe",
    "Nhịp tim",
    "Cầu vồng",
    "Cầu vồng thở",
    "Fade 2 màu",
    "Nến",
    "Lửa",
    "Cảnh sát",
    "Tiệc tùng",
    "Đại dương",
    "Hoàng hôn",
    "Nhiệt độ",
    "MEC Runner Vision",
    "MEC City of Glass",
    "MEC Glass Sunset",
    "MEC Alarm",
]

# Tốc độ mặc định (ms/nhịp) cho từng hiệu ứng — demo dùng để mỗi hiệu ứng
# hiện đúng "cá tính" của nó.
EFFECT_SPEED = {
    "Tắt": 80, "Tĩnh": 80, "Thở": 80, "Xung": 100, "Strobe": 60,
    "Nhịp tim": 60, "Cầu vồng": 60, "Cầu vồng thở": 80, "Fade 2 màu": 60,
    "Nến": 50, "Lửa": 60, "Cảnh sát": 90, "Tiệc tùng": 90,
    "Đại dương": 60, "Hoàng hôn": 60, "Nhiệt độ": 70,
    "MEC Runner Vision": 70, "MEC City of Glass": 90, "MEC Glass Sunset": 90,
    "MEC Alarm": 60,
}


def _hsv(h, s, v):
    r, g, b = colorsys.hsv_to_rgb(h % 1.0, s, v)
    return int(r * 255), int(g * 255), int(b * 255)


def _lerp(a, b, k):
    return int(a + (b - a) * k)


class Effector:
    """Tính màu cho mỗi nhịp. Giữ trạng thái random giữa các tick."""

    def __init__(self, effect: str, color=(255, 255, 255), intensity: int = 255,
                 speed_ms: int = 80, secondary=None):
        self.effect = effect
        self.r, self.g, self.b = color
        self.I = max(0, min(255, intensity))
        self.speed = max(speed_ms, 10)
        self._party_hue = 0.0
        self._party_last = -1
        # Màu phụ cho Fade: mặc định là màu bù (complement) của màu chọn
        if secondary is None:
            h, s, v = colorsys.rgb_to_hsv(self.r / 255, self.g / 255, self.b / 255)
            r2, g2, b2 = colorsys.hsv_to_rgb((h + 0.5) % 1.0, s, v)
            self.r2, self.g2, self.b2 = int(r2 * 255), int(g2 * 255), int(b2 * 255)
        else:
            self.r2, self.g2, self.b2 = secondary

    # -- helpers --------------------------------------------------------
    def _sin(self, t, period):
        return 0.5 + 0.5 * math.sin(2 * math.pi * t / period)

    # -- effects --------------------------------------------------------
    def tick(self, t_ms: int):
        t = t_ms / self.speed  # pha theo "nhịp"
        f = self.effect

        if f == "Tắt":
            return 0, 0, 0, 0
        if f == "Tĩnh":
            return self.r, self.g, self.b, self.I
        if f == "Thở":
            # chu kỳ 16 nhịp (~1.3s), giữ tối thiểu 15% để giống thở chứ không nhấp nháy
            k = 0.15 + 0.85 * self._sin(t, 16)
            return self.r, self.g, self.b, int(self.I * k)
        if f == "Xung":
            # flash nhanh rồi tàn dần theo hàm mũ (pulse thật, không phải nhấp nháy)
            p = t % 10
            k = 0.08 + 0.92 * math.exp(-p / 2.2)
            return self.r, self.g, self.b, int(self.I * k)
        if f == "Strobe":
            k = 1.0 if int(t) % 2 == 0 else 0.0
            return self.r, self.g, self.b, int(self.I * k)
        if f == "Nhịp tim":
            p = t % 14
            k = 0.05 + 1.0 * math.exp(-((p - 1.5) ** 2) / 0.6) \
                    + 0.75 * math.exp(-((p - 4.0) ** 2) / 0.5)
            return self.r, self.g, self.b, int(self.I * min(k, 1.0))
        if f == "Cầu vồng":
            r, g, b = _hsv(t / 40, 1.0, 1.0)
            return r, g, b, self.I
        if f == "Cầu vồng thở":
            r, g, b = _hsv(t / 40, 1.0, 1.0)
            return r, g, b, int(self.I * self._sin(t, 14))
        if f == "Fade 2 màu":
            k = self._sin(t, 16)
            return (_lerp(self.r, self.r2, k),
                    _lerp(self.g, self.g2, k),
                    _lerp(self.b, self.b2, k), self.I)
        if f == "Nến":
            # sóng nhiễu mượt tần số thấp (không random từng tick → hết giật),
            # thỉnh thoảng một cú nhấp chìm như gió thổi
            p = t
            k = 0.78 + 0.14 * math.sin(2 * math.pi * p / 37) \
                    + 0.06 * math.sin(2 * math.pi * p / 13.7)
            dip = 0.15 if (p % 61) < 2.5 else 0.0
            j = 14 * math.sin(2 * math.pi * p / 29)
            r = max(0, min(255, 255 + j * 0.5))
            g = max(0, min(255, 168 + j * 0.3))
            b = max(0, min(255, 70 + j * 0.1))
            return int(r), int(g), int(b), int(255 * (k - dip))
        if f == "Lửa":
            p = t
            k = 0.70 + 0.22 * math.sin(2 * math.pi * p / 34) \
                    + 0.10 * math.sin(2 * math.pi * p / 11)
            dip = 0.22 if (p % 43) < 2.0 else 0.0
            g = int(60 + 55 * (0.5 + 0.5 * math.sin(2 * math.pi * p / 25)))
            b = int(18 + 18 * (0.5 + 0.5 * math.sin(2 * math.pi * p / 16)))
            return 255, g, b, int(255 * (k - dip))
        if f == "Cảnh sát":
            p = t % 12
            if p < 5:
                return 255, 0, 0, 255
            if p < 6:
                return 60, 0, 0, 255
            if p < 11:
                return 0, 0, 255, 255
            return 0, 0, 60, 255
        if f == "Tiệc tùng":
            idx = int(t / 5)
            if idx != self._party_last:
                self._party_last = idx
                self._party_hue = random.random()
            r, g, b = _hsv(self._party_hue, 1.0, 1.0)
            return r, g, b, self.I
        if f == "Đại dương":
            h = 0.50 + 0.18 * self._sin(t, 40)
            i = int(self.I * (0.75 + 0.25 * self._sin(t, 13)))
            return _hsv(h, 0.95, 1.0) + (i,)
        if f == "Hoàng hôn":
            h = 0.00 + 0.085 * self._sin(t, 40)
            return _hsv(h, 1.0, 1.0) + (self.I,)
        if f == "Nhiệt độ":
            k = self._sin(t, 30)
            return (_lerp(255, 190, k), _lerp(175, 215, k),
                    _lerp(110, 255, k), self.I)
        # ---- Mirror's Edge Catalyst ----
        if f == "MEC Runner Vision":
            # đèn hiệu cyan của đường chạy: luôn phát sáng nhẹ, bừng mạnh theo chu kỳ
            p = t % 20
            k = 0.25 + 0.75 * math.exp(-p / 3.5)
            g = int(190 + 40 * math.sin(2 * math.pi * t / 60))
            return 0, g, 255, int(self.I * k)
        if f == "MEC City of Glass":
            # thành phố thủy tinh trắng ↔ xanh băng, chuyển chậm thanh thoát
            k = self._sin(t, 24)
            return _lerp(255, 140, k), _lerp(255, 200, k), 255, self.I
        if f == "MEC Glass Sunset":
            # key art nổi tiếng: hoàng hôn cam ↔ hồng cánh sen trên nền trắng
            k = self._sin(t, 32)
            return (_lerp(255, 255, k), _lerp(150, 90, k),
                    _lerp(70, 150, k), self.I)
        if f == "MEC Alarm":
            # bị phát hiện: đỏ báo động nháy đôi, nền đỏ mờ giữa các đợt
            p = t % 16
            if p < 2 or 4 <= p < 6:
                return 255, 25, 25, 255
            if 2 <= p < 4 or 6 <= p < 7:
                return 90, 0, 0, 255
            return 30, 0, 0, 180
        # fallback
        return self.r, self.g, self.b, self.I


if __name__ == "__main__":
    # tự kiểm tra nhanh: mỗi hiệu ứng chạy 20 tick không lỗi
    import sys
    for name in EFFECTS[1:]:
        e = Effector(name, color=(255, 90, 180), intensity=255,
                     speed_ms=EFFECT_SPEED[name])
        for i in range(20):
            out = e.tick(i * 60)
            assert all(0 <= v <= 255 for v in out), (name, out)
            assert all(isinstance(v, int) for v in out), (name, out)
        print(f"OK {name}: {e.tick(60 * 20)}")
    print("Tất cả hiệu ứng hợp lệ.")
