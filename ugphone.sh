#!/bin/bash

# 1. Kiểm tra môi trường (Ẩn log hệ thống)
for pkg in wget jq curl; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "\e[1;30m[Hệ thống]\e[0m Đang chuẩn bị: $pkg..."
        pkg install $pkg -y > /dev/null 2>&1
    fi
done

# 2. Cấu hình định danh ứng dụng
PKG_NAME="net.christianbeier.droidvnc_ng"
MAIN_ACT="net.christianbeier.droidvnc_ng.MainActivity"
INPUT_SVC="net.christianbeier.droidvnc_ng.InputService"
APK_URL="https://github.com/bk138/droidVNC-NG/releases/download/v2.1.0/droidvnc-ng-2.1.0.apk"

clear
echo -e "\e[1;32m●\e[0m \e[1;37mBắt đầu cài đặt VNC Engine...\e[0m"

# 3. Tải và cài đặt xử lý lỗi UID
wget -q -O vnc.apk $APK_URL
su -c "pm install -r $PWD/vnc.apk > /dev/null 2>&1 && sync"
echo -e "\e[1;32m●\e[0m \e[1;37mĐang đồng bộ dữ liệu ứng dụng...\e[0m"
sleep 3

# 4. Ép quyền hệ thống bằng Root
echo -e "\e[1;32m●\e[0m \e[1;37mĐang kích hoạt quyền Trợ năng & Screen Cast...\e[0m"
su -c "settings put secure enabled_accessibility_services $PKG_NAME/$INPUT_SVC > /dev/null 2>&1 && \
settings put secure accessibility_enabled 1 > /dev/null 2>&1 && \
appops set $PKG_NAME PROJECT_MEDIA allow > /dev/null 2>&1 && \
appops set $PKG_NAME SYSTEM_ALERT_WINDOW allow > /dev/null 2>&1"

# 5. Dọn dẹp
rm vnc.apk

# 6. Hướng dẫn chuyên nghiệp và chờ lệnh thực thi
echo -e "\n\e[1;33m[!] LƯU Ý KỸ THUẬT:\e[0m"
echo -e "\e[1;37m- Khi App mở: Tuyệt đối không chạm vào các mục cài đặt.\e[0m"
echo -e "\e[1;37m- Thao tác: Vuốt xuống cuối cùng -> Nhấn nút \e[1;32mSTART\e[0m \e[1;37mđể kích hoạt.\e[0m"
echo -e "\n\e[1;32m✔\e[0m \e[1;37mThiết lập hoàn tất. Nhấn \e[1;32m[ENTER]\e[0m \e[1;37mđể khởi chạy ứng dụng.\e[0m"
read -r

# 7. Khởi chạy Activity chính xác
su -c "am force-stop $PKG_NAME > /dev/null 2>&1 && am start -n $PKG_NAME/$MAIN_ACT > /dev/null 2>&1"

echo -e "\e[1;32m[OK]\e[0m Ứng dụng đã sẵn sàng trên màn hình chính."
