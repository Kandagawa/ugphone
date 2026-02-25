#!/bin/bash

# 1. Kiểm tra môi trường
for pkg in wget jq curl python; do
    if ! command -v $pkg &> /dev/null; then
        echo -e "\e[1;30m[Hệ thống]\e[0m Đang chuẩn bị: $pkg..."
        pkg install $pkg -y > /dev/null 2>&1
    fi
done

# 2. Cấu hình
PKG_NAME="net.christianbeier.droidvnc_ng"
MAIN_ACT="net.christianbeier.droidvnc_ng.MainActivity"
INPUT_SVC="net.christianbeier.droidvnc_ng.InputService"
APK_URL="https://github.com/bk138/droidVNC-NG/releases/download/v2.1.0/droidvnc-ng-2.1.0.apk"
NGROK_TOKEN="37sHv5ZlN6vRsRnXK8hrfMPfpIB_2DJ1JAwN3ff2QcHYYuYug"
WEB_PROXY_URL="https://raw.githubusercontent.com/novnc/websockify/v0.10.0/websockify/websocket.py"

clear
echo -e "\e[1;32m●\e[0m \e[1;37mBắt đầu cài đặt VNC Engine...\e[0m"

# 3. Tải và cài đặt
wget -q -O vnc.apk $APK_URL
su -c "pm install -r $PWD/vnc.apk > /dev/null 2>&1 && sync"
sleep 2

# 4. Ép quyền Root
su -c "
  settings put secure accessibility_enabled 1 && \
  settings put secure enabled_accessibility_services $PKG_NAME/$INPUT_SVC && \
  appops set $PKG_NAME PROJECT_MEDIA allow && \
  appops set $PKG_NAME SYSTEM_ALERT_WINDOW allow && \
  appops set $PKG_NAME WRITE_SETTINGS allow
" > /dev/null 2>&1
rm vnc.apk

# 5. Khởi chạy ứng dụng
echo -e "\e[1;32m●\e[0m \e[1;37mThiết lập hoàn tất.\e[0m"
for i in {3..1}; do echo -ne "\e[1;37m  Mở ứng dụng sau $i giây... \r"; sleep 1; done
su -c "am force-stop $PKG_NAME > /dev/null 2>&1 && am start -n $PKG_NAME/$MAIN_ACT > /dev/null 2>&1"

# --- FIX LỖI NHẬP LIỆU (Tham khảo từ script buy) ---
# Xóa bộ đệm để tránh trôi lệnh sau khi am start
stty sane
while [ -t 0 ] && read -t 0; do read -r; done 

while true; do
    echo -e "\n    \033[1;36m❯\033[0m \033[1;37mNhập lệnh \033[1;32mopen\033[1;37m để khởi chạy Ngrok:\033[0m "
    read -r DATA
    
    if [[ "$DATA" == "open" ]]; then 
        break 
    else
        echo -e "    \033[1;31m✘ Lệnh không hợp lệ! Vui lòng nhập đúng 'open'.\033[0m"
    fi
done
# --------------------------------------------------

echo -e "    \e[1;32m●\e[0m \e[1;37mĐang khởi tạo kết nối (5900 & 8080)...\e[0m"

# 6. Chạy Websockify & Ngrok
if [ ! -f "websockify.py" ]; then
    wget -q -O websockify.py $WEB_PROXY_URL
fi

python websockify.py --daemon 8080 localhost:5900 > /dev/null 2>&1

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

echo -ne "    \e[1;32m●\e[0m \e[1;37mĐang lấy link từ máy chủ...\r"
sleep 7

# Lấy Link Public
APP_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.name=="vnc_app") | .public_url')
WEB_URL=$(curl -s http://127.0.0.1:4040/api/tunnels | jq -r '.tunnels[] | select(.name=="vnc_web") | .public_url')

clear
echo -e "\n    \033[1;38;5;141m[KẾT NỐI SẴN SÀNG]\033[0m"
echo -e "    \033[1;32m✅ App:\033[0m \033[1;36m$APP_URL\033[0m"
echo -e "    \033[1;32m✅ Web:\033[0m \033[1;36m$WEB_URL/vnc.html\033[0m"
echo -e "\n    \033[1;30m(Quay lại đây nếu đã Start xong app)\033[0m"

rm ngrok_vnc.yml
