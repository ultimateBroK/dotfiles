# Điều khiển đèn RGB bàn phím — ASUS Vivobook S14 (M5406WA)

Chương trình GUI + thư viện điều khiển đèn nền bàn phím RGB trên CachyOS/Arch.

## Vị trí & cách dùng nhanh

- File gốc: `~/Downloads/dotfiles/asus-kbd-rgb/` (dotfiles repo)
- `~/asus-kbd-rgb` là **symlink** trỏ vào thư mục trên — mọi đường dẫn cũ vẫn chạy.
- Lệnh zsh (đã thêm vào `~/.zshrc`):
  - `kbd` — mở GUI
  - `kbd --daemon` — chạy hiệu ứng nền (tự background hóa)
  - `kbd --apply` — áp màu tĩnh đã lưu rồi thoát
  - `kbd-stop` — dừng daemon nền
- Nhớ `source ~/.zshrc` hoặc mở terminal mới sau khi sửa.

## Vì sao đèn không điều khiển được?

Có **hai vấn đề độc lập** trên máy này:

1. **Phím Fn+F4 (đèn bàn phím) không hoạt động**
   - Gói `faustus-dkms-git` (module dành cho dòng **TUF Gaming** — vô dụng trên
     Vivobook) cài file `/etc/modprobe.d/faustus.conf` **blacklist cả
     `asus_wmi` lẫn `asus_nb_wmi`** → driver `asus-nb-wmi` (xử lý phím nóng
     WMI, gồm cả phím đèn bàn phím) không bao giờ được nạp.
   - Ngoài ra, EC của máy ở trạng thái **OOBE** (chưa "setup lần đầu") nên
     phần cứng cũng không nhận lệnh bật/tắt đèn. Phải ghi `dev_id 0x5002f` qua
     debugfs của asus-nb-wmi để đánh dấu OOBE đã xong (cách của gói
     `asus-vivobook-rgb-keyboard` đã cài sẵn).

2. **Không đổi được màu RGB**
   - Bàn phím này **không dùng WMI/ACPI cho RGB**. Màu được điều khiển qua
     controller **ITE5570** (vendor `0B05`, product `5570`) nói giao thức
     **HID LampArray** (usage page `0x59`) — chính là nền tảng Windows
     Dynamic Lighting. asusctl/aura không đụng tới được vì nó chỉ hỗ trợ
     ROG/TUF.
   - Thư mục này giao tiếp trực tiếp với hidraw bằng giao thức LampArray
     chuẩn: đặt màu, độ sáng, và hiệu ứng động chạy bằng phần mềm.

## Cài đặt

```bash
sudo bash ~/asus-kbd-rgb/setup.sh
```

Script làm 6 việc: cài `tk` (GUI), thêm udev rule cho ITE5570 (không cần root
để đổi màu), gỡ blacklist faustus, nạp `asus_nb_wmi`, bật OOBE service, kiểm
tra `/sys/class/leds/asus::kbd_backlight`.

> Lưu ý: `setup.sh` chỉ vô hiệu hóa file config của faustus, không gỡ gói.
> Nếu muốn dọn sạch: `sudo pacman -R faustus-dkms-git` (không cần thiết).

## Dùng

```bash
python3 ~/asus-kbd-rgb/asus_rgb_gui.py           # GUI (tự áp dụng cấu hình đã lưu)
python3 ~/asus-kbd-rgb/asus_rgb_gui.py --daemon  # chạy hiệu ứng nền, không GUI
python3 ~/asus-kbd-rgb/lamparray.py              # test nhanh: trắng 5s rồi tắt
python3 ~/asus-kbd-rgb/asus_rgb_gui.py --apply   # áp dụng màu tĩnh 1 lần rồi thoát
```

GUI có: chọn màu (3 thanh trượt RGB + ô hex + 10 màu nhanh), độ sáng, hiệu
ứng (Tắt / Tĩnh / Thở / Cầu vồng / ... / 4 hiệu ứng MEC), tốc độ hiệu ứng,
nút "Lưu mặc định" (ghi `~/.config/asus-kbd-rgb.json`) và tùy chọn **tự áp
dụng khi đăng nhập**.

## Giữ hiệu ứng chạy sau khi đóng app / khởi động lại

- Đóng GUI với một hiệu ứng động đang chọn → GUI tự lưu cấu hình và **khởi
  động daemon nền** (`--daemon`) chạy tiếp hiệu ứng đó — đèn không đứng yên.
- "Tắt"/"Tĩnh": ghi 1 lần lên phần cứng là đủ, không cần daemon.
- Mở lại GUI → GUI tự áp dụng cấu hình đã lưu và dừng daemon (tránh hai
  tiến trình cùng ghi).
- Sau reboot: đèn reset về mặc định → bật checkbox "Tự áp dụng khi đăng
  nhập" (desktop entry chạy `--daemon` lúc login) để hiệu ứng được áp lại
  tự động.
- Daemon ghi pid vào `~/.config/asus-kbd-rgb.pid`; dừng thủ công:
  `kill $(cat ~/.config/asus-kbd-rgb.pid)`.

## Hiệu ứng (đã kiểm chứng trên đèn thật 08/2026)

Controller KHÔNG có animation trong firmware (bật auto mode 0x46=1 chỉ ra
trắng mặc định) → mọi hiệu ứng chạy bằng phần mềm (gửi 0x45 liên tục).
Đèn 1 vùng → hiệu ứng theo thời gian. 19 hiệu ứng trong effects.py:

- Tĩnh, Thở (sin giữ 15% sáng), Xung (flash + tàn dần hàm mũ), Strobe,
  Nhịp tim (2 nhịp/lần), Cầu vồng (2.4s/vòng), Cầu vồng thở,
  Fade 2 màu (màu ↔ màu bù), Nến (nhiễu sin mượt + nhấp chìm), Lửa,
  Cảnh sát (đỏ→tối→xanh→tối), Tiệc tùng (đổi màu ngẫu nhiên liên tục),
  Đại dương (xanh↔cyan + sóng sáng), Hoàng hôn (đỏ→vàng), Nhiệt độ
  (trắng ấm↔lạnh).

- Nhóm Mirror's Edge Catalyst (MEC): Runner Vision (cyan đèn hiệu đường
  chạy, giữ sáng 25% + bừng theo chu kỳ 1.4s), City of Glass (trắng ↔
  xanh băng chuyển chậm), Glass Sunset (cam ↔ hồng cánh sen — key art
  hoàng hôn), Alarm (đỏ báo động nháy đôi + nền đỏ mờ).

Kinh nghiệm chỉnh: hiệu ứng "cháy/nến" dùng random mỗi tick sẽ bị GIẬT —
phải dùng sóng sin tần số thấp + thỉnh thoảng nhấp chìm.

## Ghi chú kỹ thuật

- Đèn là **RGB 1 vùng** (single-zone) — chỉ có một màu cho cả bàn phím.
  "Chuyển động" ở đây là hiệu ứng theo thời gian (đổi màu/độ sáng liên tục),
  không có chuyển động không gian từng phím.
- **Pi-bẫy quan trọng** (đã test trên M5406WA): report `0x46` (host/firmware
  mode) phải gửi **đúng 2 byte** `[0x46, mode]` NGAY TRƯỚC mỗi lệnh màu.
  Nếu gửi 3 byte (kèm byte duration như trong descriptor) firmware không vào
  host mode → đèn luôn trắng bất kể byte màu (ioctl vẫn không báo lỗi!).
- Feature report dùng: `0x41` (attributes), `0x45` (set color:
  `[0x45, 1, start<H>, end<H>, r, g, b, intensity]`), `0x46` (host/firmware
  mode, 2 byte). Ngoài ra controller còn giao diện vendor (usage page
  0xFF59, report 0x31-0x36) — không cần dùng.
- Fn+F4 điều khiển đèn **trắng** (4 mức + tắt) qua EC — độc lập với màu RGB
  của GUI. Nếu bấm Fn+F4 khi đang để màu, đèn sẽ chuyển sang trắng; bấm tới
  khi tắt rồi đặt màu lại qua GUI.
- Nguồn: thread Arch BBS "RGB Keyboard on ASUS Vivobook S 16 (5606)"
  (bài của Zeleekala, 03/2026, test trên đúng M5406WA) +
  dự án [VRGB](https://github.com/vrgb-dev/vrgb) (xác nhận hoạt động trên
  M5406WA; protocol của thư mục này khớp byte-for-byte với VRGB) +
  github.com/kockahonza/asus-vivobook-rgb-keyboard.
