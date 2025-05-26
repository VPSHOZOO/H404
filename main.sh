#!/bin/bash
clear
# =============================================
# Script untuk menjalankan Ubuntu RDP/VNC + Ngrok
# =============================================

# 1. Install Docker (jika belum terpasang)
if ! command -v docker &> /dev/null; then
    echo "Installing Docker..."
    sudo apt update -y
    clear
    sudo apt install -y docker.io  
    clear
    sudo systemctl enable --now docker
    clear
    sudo usermod -aG docker $USER
    echo "Docker installed. Please logout/login or reboot to apply changes."
    exit 1
fi

# 2. Pull Docker image (Ubuntu dengan NoVNC/RDP)
echo "Starting Docker container..."
docker run --privileged --shm-size 1g -d -p 3389:3389 \
  -e VNC_PASSWD="123456" \
  -e SCREEN_WIDTH=1920 \
  -e SCREEN_HEIGHT=1080 \
  --name ubuntu-rdp \
  thuonghai2711/ubuntu-novnc-pulseaudio:20.0

echo "Docker container running on port 3389 (RDP)."

# 3. Install Ngrok (jika belum terpasang)
if ! command -v ngrok &> /dev/null; then
    echo "Installing Ngrok..."
    curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null
    echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | sudo tee /etc/apt/sources.list.d/ngrok.list
    sudo apt update && sudo apt install -y ngrok
fi

# 4. Autentikasi Ngrok (ganti dengan token Anda)
if [ ! -f ~/.config/ngrok/ngrok.yml ]; then
    read -p "Masukkan Ngrok Auth Token (dapat dari https://dashboard.ngrok.com): " NGROK_TOKEN
    ngrok config add-authtoken "$NGROK_TOKEN"
fi

# 5. Forward RDP via Ngrok TCP
echo "Starting Ngrok TCP tunnel for RDP (port 3389)..."
ngrok tcp 3389 --log=stdout > ngrok.log &

# Tunggu 5 detik untuk Ngrok memulai
sleep 5

# 6. Dapatkan URL Ngrok
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[0].public_url')
if [ -z "$NGROK_URL" ]; then
    echo "Gagal mendapatkan URL Ngrok. Cek 'ngrok.log' untuk detail."
    exit 1
fi

echo "==========================================="
echo "✨ RDP siap diakses secara remote! ✨"
echo "Alamat RDP: $NGROK_URL"
echo "Username: ubuntu/root (tergantung image)"
echo "Password: YourSecurePassword123"
echo "==========================================="
echo "Gunakan 'Ctrl+C' untuk menghentikan Ngrok."
echo "Jalankan 'docker stop ubuntu-rdp' untuk menghentikan container."

# Tetap running sampai user menekan Ctrl+C
wait
