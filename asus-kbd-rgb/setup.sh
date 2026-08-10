#!/bin/bash
# Cài đặt điều khiển đèn RGB bàn phím ASUS Vivobook S14 (M5406WA) trên Arch/CachyOS.
# Chạy:  sudo bash setup.sh
set -euo pipefail

echo "==> [1/6] Cài tk (thư viện GUI)"
pacman -S --needed --noconfirm tk

echo "==> [2/6] Cài udev rule cho controller ITE5570 (khỏi cần root để đổi màu)"
cat > /etc/udev/rules.d/99-asus-kbd-rgb.rules <<'EOF'
# ITE5570 là HID over I2C: không có idVendor/idProduct -> match theo modalias
KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{modalias}=="hid:*v00000B05p00005570", MODE="0660", GROUP="input"
EOF
udevadm control --reload-rules
udevadm trigger --subsystem-match=hidraw

echo "==> [3/6] Gỡ blacklist asus_wmi/asus_nb_wmi do gói faustus (gói cho TUF Gaming, vô dụng trên Vivobook)"
cp -n /etc/modprobe.d/faustus.conf /etc/modprobe.d/faustus.conf.bak 2>/dev/null || true
sed -i '/^blacklist asus_wmi$/d; /^blacklist asus_nb_wmi$/d' /etc/modprobe.d/faustus.conf
# Tắt dòng nạp module faustus lúc boot (module không load được, chỉ gây log lỗi)
sed -i 's/^faustus$/#faustus/' /etc/modules-load.d/faustus.conf 2>/dev/null || true

echo "==> [4/6] Nạp driver asus-nb-wmi (xử lý phím nóng, gồm Fn+F4 đèn bàn phím)"
modprobe asus_nb_wmi
sleep 1

echo "==> [5/6] Bật OOBE mode (đánh dấu 'đã setup lần đầu' cho EC — bắt buộc để Fn+F4 điều khiển đèn)"
systemctl enable --now asus-vivobook-rgb-keyboard.service
sleep 1

echo "==> [6/6] Kiểm tra"
if [ -d /sys/class/leds/asus::kbd_backlight ]; then
  echo "OK: /sys/class/leds/asus::kbd_backlight tồn tại"
  echo "   brightness: $(cat /sys/class/leds/asus::kbd_backlight/brightness)/$(cat /sys/class/leds/asus::kbd_backlight/max_brightness)"
  echo "   Thử bật mức 2 (Fn+F4 giờ phải chạy được)"
  echo 2 > /sys/class/leds/asus::kbd_backlight/brightness
else
  echo "CẢNH BÁO: chưa thấy asus::kbd_backlight. Kiểm tra: lsmod | grep asus_nb_wmi"
fi

echo
echo "Xong! Giờ chạy:  python3 ~/asus-kbd-rgb/lamparray.py   (test đổi màu 5 giây)"
echo "            hoặc:  python3 ~/asus-kbd-rgb/asus_rgb_gui.py  (mở GUI)"
