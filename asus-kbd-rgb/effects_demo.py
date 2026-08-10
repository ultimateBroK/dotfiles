#!/usr/bin/env python3
"""Kiểm chứng toàn bộ hiệu ứng trên đèn thật — chạy tuần tự, mỗi cái ~6s.

QUAN SÁT BÀN PHÍM và ghi chú hiệu ứng nào đẹp / lỗi / không nhìn thấy.
Cuối cùng test firmware auto mode (animation có sẵn trong controller).
"""
import time
from lamparray import LampArray
from effects import Effector, EFFECTS, EFFECT_SPEED

DEMO_SECONDS = 6
BASE_COLOR = (255, 90, 180)  # hồng — để Fade/Nến trông rõ

with LampArray() as la:
    print("=== KIỂM CHỨNG HIỆU ỨNG (mỗi cái ~%ds) ===" % DEMO_SECONDS)
    for name in EFFECTS[1:]:  # bỏ "Tắt"
        speed = EFFECT_SPEED[name]
        eff = Effector(name, color=BASE_COLOR, intensity=255, speed_ms=speed)
        print(f"\n>>> {name}  (speed={speed}ms)")
        t0 = time.monotonic()
        last = 0
        while time.monotonic() - t0 < DEMO_SECONDS:
            t_ms = int((time.monotonic() - t0) * 1000)
            r, g, b, i = eff.tick(t_ms)
            la.set_color(r, g, b, i)
            # in thay đổi màu lớn để dễ đối chiếu
            if abs(r - last) > 60:
                last = r
            time.sleep(0.03)
        la.set_color(255, 255, 255, 255)  # trắng giữa các hiệu ứng
        time.sleep(0.8)

    print("\n=== TEST FIRMWARE AUTO MODE (0x46, 0x01) — 6s ===")
    print("(Nếu firmware có animation sẵn, đèn sẽ tự chạy không cần phần mềm)")
    la._send([0x46, 0x01])
    time.sleep(6)
    la._send([0x46, 0x00])

    print("\n=== KẾT THÚC: đặt trắng 100% ===")
    la.set_color(255, 255, 255, 255)
