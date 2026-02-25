#!/bin/bash

# 1. Kiểm tra và cài đặt các package còn thiếu
for pkg in wget jq curl; do
    if ! command -v $pkg &> /dev/null; then
        echo "Đang cài đặt $pkg..."
        pkg install $pkg -y
    fi
done

# 2. Khai báo biến để dễ quản lý (Dùng Package chuẩn đã tìm thấy)
PKG_NAME="net.christianbeier.droidvnc_ng"
MAIN_ACT="net.christianbeier.droidvnc_ng.MainActivity"
INPUT_SVC="net.christianbeier.droidvnc_ng.InputService"
APK_URL="https://github.com/bk138/droidVNC-NG/releases/download/v2.1.0/droidvnc-ng-2.1.0.apk"

echo "Bắt đầu tải và cài đặt VNC..."

# 3. Tải và cài đặt (Fix lỗi No UID và Unable to open file)
wget -O vnc.apk $APK_URL
su -c "pm install -r $PWD/vnc.apk && sync" && sleep 3

# 4. Ép cấp full quyền bằng Root (Fix lỗi DENIED và UNKNOWN)
echo "Đang ép cấp quyền hệ thống..."
su -c "settings put secure enabled_accessibility_services $PKG_NAME/$INPUT_SVC && \
settings put secure accessibility_enabled 1 && \
appops set $PKG_NAME PROJECT_MEDIA allow && \
appops set $PKG_NAME SYSTEM_ALERT_WINDOW allow"

# 5. Khởi động lại App và dọn dẹp
su -c "am force-stop $PKG_NAME && am start -n $PKG_NAME/$MAIN_ACT"
rm vnc.apk

echo -e "\n\e[1;32m--- CÀI ĐẶT & CẤP QUYỀN HOÀN TẤT ---"
echo -e "\e[1;33mNếu dùng Xiaomi, hãy bật thêm 'Hiển thị cửa sổ pop-up' nếu START vẫn lỗi.\e[0m"

