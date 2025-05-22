#!/bin/bash
# enhanced_performance_mode.sh - Quản lý hiệu suất Hyprland tối giản

# --- Cấu hình và biến môi trường ---
HYPR_CONFIG="$HOME/.config/hypr"
CURRENT_MODE_FILE="$HYPR_CONFIG/logs/.current_mode"
LOG_FILE="$HYPR_CONFIG/logs/performance_mode.log"
NOTIFICATION_TIMEOUT=3000

# Tìm đường dẫn tuyệt đối của các lệnh
HYPRCTL=$(which hyprctl 2>/dev/null || echo "/usr/bin/hyprctl")
NOTIFY_SEND=$(which dunstify 2>/dev/null || echo "/usr/bin/dunstify")
TOFI=$(which tofi 2>/dev/null || echo "/usr/bin/tofi")
WOFI=$(which wofi 2>/dev/null || echo "/usr/bin/wofi")
ROFI=$(which rofi 2>/dev/null || echo "/usr/bin/rofi")

# --- Khởi tạo ---
mkdir -p "$HYPR_CONFIG"
touch "$LOG_FILE"

# Hàm ghi log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Hàm thực thi hyprctl
execute_hyprctl() {
    $HYPRCTL "$1" "$2" 2>/dev/null || {
        log "WARNING: Failed to execute 'hyprctl $1 $2'"
    }
}

# Hiển thị thông báo 
show_notification() {
    local mode="$1"
    local title="$2"
    local message="$3"
    local icon="preferences-system"
    
    # Sử dụng biểu tượng mặc định dựa vào chế độ
    case "$mode" in
        normal) icon="preferences-system" ;;
        balanced) icon="preferences-system-performance" ;;
        performance) icon="system-run" ;;
        gaming) icon="applications-games" ;;
        battery) icon="battery-good" ;;
        presentation) icon="video-display" ;;
        info) icon="dialog-information" ;;
        error) icon="dialog-error" ;;
    esac
    
    $NOTIFY_SEND -t $NOTIFICATION_TIMEOUT -i "$icon" "$title" "$message"
    log "Notification: [$title] $message"
}

# Hàm xử lý CPU governor - SỬA ĐỔI để tránh khựng
setup_cpu_governor() {
    local governor="$1"
    
    # Nếu không có quyền sudo không cần mật khẩu, bỏ qua thay đổi governor
    if ! sudo -n true 2>/dev/null; then
        log "Skipping CPU governor change (no sudo privileges without password)"
        return 0
    fi
    
    # Chỉ thử thay đổi governor nếu có quyền sudo không cần mật khẩu
    if [ -f "/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor" ]; then
        current_governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null)
        
        if [ "$current_governor" = "$governor" ]; then
            return 0
        fi
        
        # Thêm timeout để tránh treo
        timeout 1 sudo -n tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor <<< "$governor" > /dev/null 2>&1 || {
            log "Failed to set CPU governor with sudo"
        }
    fi
}

# --- Định nghĩa các chế độ ---
setup_normal_mode() {
    log "Setting up normal mode"
    execute_hyprctl keyword "animations:enabled true"
    execute_hyprctl keyword "decoration:blur:enabled true"
    execute_hyprctl keyword "decoration:blur:size 3"
    execute_hyprctl keyword "decoration:blur:passes 1"
    execute_hyprctl keyword "decoration:shadow:enabled true"
    execute_hyprctl keyword "decoration:rounding 10"
    execute_hyprctl keyword "general:gaps_in 5"
    execute_hyprctl keyword "general:gaps_out 5"
    execute_hyprctl keyword "decoration:active_opacity 1.0"
    execute_hyprctl keyword "decoration:inactive_opacity 1.0"
    
    setup_cpu_governor "schedutil"
}

setup_balanced_mode() {
    log "Setting up balanced mode"
    execute_hyprctl keyword "animations:enabled true"
    execute_hyprctl keyword "decoration:blur:enabled true"
    execute_hyprctl keyword "decoration:blur:size 2"
    execute_hyprctl keyword "decoration:blur:passes 1"
    execute_hyprctl keyword "decoration:shadow:enabled true"
    execute_hyprctl keyword "decoration:rounding 8"
    execute_hyprctl keyword "general:gaps_in 3"
    execute_hyprctl keyword "general:gaps_out 3"
    
    setup_cpu_governor "schedutil"
}

setup_performance_mode() {
    log "Setting up performance mode"
    execute_hyprctl keyword "animations:enabled false"
    execute_hyprctl keyword "decoration:blur:enabled false"
    execute_hyprctl keyword "decoration:shadow:enabled false"
    execute_hyprctl keyword "decoration:rounding 0"
    execute_hyprctl keyword "general:gaps_in 0"
    execute_hyprctl keyword "general:gaps_out 0"
    
    setup_cpu_governor "performance"
}

setup_gaming_mode() {
    log "Setting up gaming mode"
    execute_hyprctl keyword "animations:enabled false"
    execute_hyprctl keyword "decoration:blur:enabled false"
    execute_hyprctl keyword "decoration:shadow:enabled false"
    execute_hyprctl keyword "decoration:rounding 0"
    execute_hyprctl keyword "general:gaps_in 0"
    execute_hyprctl keyword "general:gaps_out 0"
    
    # Kích hoạt gamemode nếu có - SỬA ĐỔI để ngăn treo
    if command -v gamemoded &> /dev/null; then
        log "Attempting to activate gamemode"
        # Dừng gamemode nếu đang chạy (với timeout)
        timeout 1 gamemoded -r 2>/dev/null || true
        
        # Khởi động gamemode trong background mà không đợi kết quả
        (timeout 1 gamemoded >/dev/null 2>&1 &) &
        log "Gamemode activation request sent"
    else
        log "gamemode not installed, skipping"
    fi
    
    setup_cpu_governor "performance"
}

setup_battery_mode() {
    log "Setting up battery mode"
    execute_hyprctl keyword "animations:enabled false"
    execute_hyprctl keyword "decoration:blur:enabled false"
    execute_hyprctl keyword "decoration:shadow:enabled false"
    execute_hyprctl keyword "decoration:rounding 5"
    execute_hyprctl keyword "general:gaps_in 3"
    execute_hyprctl keyword "general:gaps_out 3"
    execute_hyprctl keyword "decoration:inactive_opacity 0.9"
    
    setup_cpu_governor "powersave"
}

setup_presentation_mode() {
    log "Setting up presentation mode"
    execute_hyprctl keyword "animations:enabled true"
    execute_hyprctl keyword "decoration:blur:enabled true"
    execute_hyprctl keyword "decoration:blur:size 2"
    execute_hyprctl keyword "decoration:shadow:enabled true"
    execute_hyprctl keyword "decoration:rounding 10"
    execute_hyprctl keyword "general:gaps_in 8"
    execute_hyprctl keyword "general:gaps_out 8"
    execute_hyprctl keyword "misc:mouse_move_enables_dpms true"
    execute_hyprctl keyword "misc:key_press_enables_dpms true"
    
    # Vô hiệu hóa screensaver/lock
    if systemctl --user is-active hypridle &>/dev/null; then
        systemctl --user stop hypridle &>/dev/null
        echo "hypridle" > /tmp/presentation_mode_service
        log "Stopped hypridle for presentation mode"
    fi
    
    setup_cpu_governor "schedutil"
}

# Lưu trạng thái chế độ hiện tại
save_current_mode() {
    echo "$1" > "$CURRENT_MODE_FILE"
    log "Saved current mode: $1"
}

# Hiển thị giao diện người dùng để chọn chế độ
show_mode_picker() {
    log "Opening mode picker"
    
    local MODE=""
    
    # Thử sử dụng các menu khác nhau theo thứ tự ưu tiên
    if [ -x "$TOFI" ]; then
        MODE=$(echo -e "normal\nbalanced\nperformance\ngaming\nbattery\npresentation" | $TOFI --prompt-text "Select performance mode: ")
    elif [ -x "$ROFI" ]; then
        MODE=$(echo -e "normal\nbalanced\nperformance\ngaming\nbattery\npresentation" | $ROFI -dmenu -p "Select performance mode:")
    elif [ -x "$WOFI" ]; then
        MODE=$(echo -e "normal\nbalanced\nperformance\ngaming\nbattery\npresentation" | $WOFI -d -p "Select performance mode:")
    else
        show_notification "error" "Performance Mode Error" "No UI picker (tofi, rofi, or wofi) found"
        exit 1
    fi
    
    # Chỉ áp dụng nếu người dùng đã chọn một chế độ
    if [ -n "$MODE" ]; then
        apply_mode "$MODE"
    else
        log "Mode selection canceled by user"
        exit 0
    fi
}

# Dọn dẹp chế độ trước - SỬA ĐỔI để tránh khựng
cleanup_previous_mode() {
    log "Cleaning up previous mode settings"
    
    # Dừng gamemode nếu đang chạy
    if command -v gamemoded &> /dev/null; then
        timeout 1 gamemoded -r 2>/dev/null || true
    fi
    
    # Khởi động lại các dịch vụ đã dừng (với timeout)
    if [ -f /tmp/presentation_mode_service ]; then
        service=$(cat /tmp/presentation_mode_service)
        if [ "$service" = "hypridle" ]; then
            timeout 1 systemctl --user start hypridle 2>/dev/null || true
        fi
        rm -f /tmp/presentation_mode_service
    fi
}

# Kiểm tra và cài đặt các yêu cầu cần thiết
check_requirements() {
    local missing_deps=()
    
    # Kiểm tra các lệnh cần thiết
    if [ ! -x "$HYPRCTL" ]; then
        missing_deps+=("hyprctl")
    fi
    
    if [ ! -x "$NOTIFY_SEND" ]; then
        missing_deps+=("dunstify")
    fi
    
    # Kiểm tra ít nhất một trong các công cụ chọn
    if [ ! -x "$TOFI" ] && [ ! -x "$WOFI" ] && [ ! -x "$ROFI" ]; then
        missing_deps+=("tofi/wofi/rofi")
    fi
    
    # Nếu thiếu lệnh cần thiết, hiển thị thông báo
    if [ ${#missing_deps[@]} -gt 0 ]; then
        log "ERROR: Missing required dependencies: ${missing_deps[*]}"
        $NOTIFY_SEND -t 5000 -i "dialog-error" "Performance Mode Error" \
            "Missing required dependencies: ${missing_deps[*]}"
        exit 1
    fi
    
    # Kiểm tra quyền truy cập Hyprland
    if ! $HYPRCTL monitors &> /dev/null; then
        log "ERROR: Cannot communicate with Hyprland"
        $NOTIFY_SEND -t 5000 -i "dialog-error" "Performance Mode Error" \
            "Cannot communicate with Hyprland"
        exit 1
    fi
}

# Áp dụng chế độ được chọn
apply_mode() {
    local mode="$1"
    local prev_mode=""
    
    # Kiểm tra yêu cầu trước khi thực thi
    check_requirements
    
    if [ -f "$CURRENT_MODE_FILE" ]; then
        prev_mode=$(cat "$CURRENT_MODE_FILE")
    fi
    
    # Nếu chuyển đến cùng một chế độ, hiển thị thông báo và thoát
    if [ "$prev_mode" = "$mode" ]; then
        show_notification "$mode" "Already in $mode mode" "No changes needed."
        exit 0
    fi
    
    # Dọn dẹp các thiết lập trước đó
    cleanup_previous_mode
    
    # Áp dụng thiết lập chế độ mới
    case "$mode" in
        normal)
            setup_normal_mode
            show_notification "normal" "Normal Mode Activated" "Full animations and effects enabled."
            save_current_mode "normal"
            ;;
        balanced)
            setup_balanced_mode
            show_notification "balanced" "Balanced Mode Activated" "Reduced effects for better performance."
            save_current_mode "balanced"
            ;;
        performance)
            setup_performance_mode
            show_notification "performance" "Performance Mode Activated" "Minimal effects for maximum performance."
            save_current_mode "performance"
            ;;
        gaming)
            setup_gaming_mode
            show_notification "gaming" "Gaming Mode Activated" "Maximum performance configuration."
            save_current_mode "gaming"
            ;;
        battery)
            setup_battery_mode
            show_notification "battery" "Battery Saving Mode Activated" "Power saving optimizations enabled."
            save_current_mode "battery"
            ;;
        presentation)
            setup_presentation_mode
            show_notification "presentation" "Presentation Mode Activated" "Screen-lock disabled. Optimized for presentations."
            save_current_mode "presentation"
            ;;
        *)
            # Nếu không có chế độ hợp lệ, hiển thị menu chọn
            show_mode_picker
            ;;
    esac
    
    log "Performance Mode Script Completed"
    exit 0
}

# Hàm main - điểm vào chính của script
main() {
    log "--- Performance Mode Script Started ---"
    
    # Kiểm tra xem có tham số đầu vào không
    if [ $# -eq 0 ]; then
        # Nếu không có tham số, mở menu chọn chế độ
        show_mode_picker
    else
        # Nếu có tham số, áp dụng chế độ tương ứng
        apply_mode "$1"
    fi
}

# Gọi hàm main với tất cả tham số
main "$@"
