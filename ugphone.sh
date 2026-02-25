#!/bin/bash

# 1. Kiểm tra và cài đặt các package (Thêm python để chạy Web Bridge)
for pkg in wget jq curl python; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "\e[1;30m[Hệ thống]\e[0m Đang chuẩn bị: $pkg..."
        pkg install $pkg -y > /dev/null 2>&1
    fi
done

# 2. Khai báo biến (Dùng bản ổn định nhất)
PKG_NAME="net.christianbeier.droidvnc_ng"
MAIN_ACT="net.christianbeier.droidvnc_ng.MainActivity"
INPUT_SVC="net.christianbeier.droidvnc_ng.InputService"
APK_URL="https://github.com/bk138/droidVNC-NG/releases/download/v2.1.0/droidvnc-ng-2.1.0.apk"
NGROK_TOKEN="37sHv5ZlN6vRsRnXK8hrfMPfpIB_2DJ1JAwN3ff2QcHYYuYug"
WEB_PROXY_URL="https://raw.githubusercontent.com/novnc/websockify/v0.10.0/websockify/websocket.py"

clear
echo -e "\e[1;32m●\e[0m \e[1;37mBắt đầu cài đặt VNC Engine...\e[0m"

# 3. Tải và cài đặt App VNC
wget -q -O vnc.apk $APK_URL
su -c "pm install -r $PWD/vnc.apk > /dev/null 2>&1 && sync"
echo -e "\e[1;32m●\e[0m \e[1;37mĐang đồng bộ hệ thống...\e[0m"
sleep 2

# 4. Ép quyền Root (Fix triệt để lỗi Accessibility và Screen Cast)
echo -e "\e[1;32m●\e[0m \e[1;37mĐang kích hoạt quyền Trợ năng & Screen Cast...\e[0m"
su -c "
  settings put secure accessibility_enabled 1 && \
  settings put secure enabled_accessibility_services $PKG_NAME/$INPUT_SVC && \
  appops set $PKG_NAME PROJECT_MEDIA allow && \
  appops set $PKG_NAME SYSTEM_ALERT_WINDOW allow && \
  appops set $PKG_NAME WRITE_SETTINGS allow
" > /dev/null 2>&1
rm vnc.apk

# 5. Thông báo và mở App
echo -e "\e[1;32m●\e[0m \e[1;37mThiết lập hoàn tất.\e[0m"
echo -e "\e[1;33m- Quay lại đây nếu đã Start xong.\e[0m"

for i in {3..1}; do
    echo -ne "\e[1;37m  Mở ứng dụng sau $i giây... \r"
    sleep 1
done

su -c "am force-stop $PKG_NAME > /dev/null 2>&1 && am start -n $PKG_NAME/$MAIN_ACT > /dev/null 2>&1"
echo -e "\e[1;32m[OK]\e[0m Ứng dụng đã được mở."

# 6. Kích hoạt Web VNC & Ngrok
echo -e "\n\e[1;37mNhập lệnh \e[1;32mopen\e[1;37m để khởi chạy cổng VNC & Web:\e[0m"
read -r user_cmd

if [ "$user_cmd" == "open" ]; then
    echo -e "\e[1;32m●\e[0m \e[1;37mĐang khởi tạo kết nối (5900 & 8080)...\e[0m"
    
    # FIX WEB LỎ: Tải bản websockify đầy đủ code, chạy ngay không cần cài đặt
    if [ ! -f "websockify.py" ]; then
        wget -q -O websockify.py $WEB_PROXY_URL
    fi
    
    # Chạy cầu nối Web ngầm bằng Python
    python websockify.py --daemon 8080 localhost:5900 > /dev/null 2>&1
    
    # Cấu hình Ngrok đa cổng
    ./ngrok config add-authtoken $NGROK_TOKEN > /dev/null 2>&1
    cat <<EOF > ngrok_vnc.yml
authtoken: $NGROK_TOKEN
tunnels:
  vnc_app:
    proto: tcp
    addr: 5900
  vnc_web:
    proto: http
    addr: 8080
EOF

    (./ngrok start --all --config=ngrok_vnc.yml > /dev/null 2>&1 &)
    
    echo -ne "\e[1;32m●\e[0m \e[1;37mĐang lấy link từ máy chủ...\r"
    sleep 6
    
    # Lấy Link Public từ API Ngrok
    APP_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.name=="vnc_app") | .public_url')
    WEB_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.name=="vnc_web") | .public_url')
    
    clear
    echo -e "\e[1;32m--- KẾT NỐI ĐÃ SẴN SÀNG ---\e[0m"
    echo -e "\e[1;37m1. Dùng App VNC Viewer:\e[0m"
    echo -e "   \e[1;36m$APP_URL\e[0m"
    echo -e "\e[1;37m2. Dùng Web (noVNC):\e[0m"
    echo -e "   \e[1;36m$WEB_URL/vnc.html\e[0m"
    echo -e "\n\e[1;33mChú ý: Nhấn START trong app rồi mới dùng link!\e[0m"
    
    rm ngrok_vnc.yml
else
    echo -e "\e[1;31m[Hủy]\e[0m Lệnh không đúng."
fi
