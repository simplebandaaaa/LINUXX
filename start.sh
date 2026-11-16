
#!/bin/bash
set -e

# ---- Password ----
RDP_PASSWORD="${RDP_PASSWORD:-umeshedittz123}"
echo "ubuntu:${RDP_PASSWORD}" | chpasswd

# ---- Volume defaults ----
if [ ! -e /home/ubuntu/.xsession ]; then
    cp -a /opt/ubuntu-home-defaults/. /home/ubuntu/
fi

chown -R ubuntu:ubuntu /home/ubuntu

# ---- Permanent wallpaper autostart ----
mkdir -p /etc/xdg/autostart

cat > /etc/xdg/autostart/umesheditz-wallpaper.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Umesh Editz Wallpaper
Exec=/usr/local/bin/set-wallpaper.sh
OnlyShowIn=XFCE;
Terminal=false
Hidden=false
EOF

# ---- /dev/shm ----
mount -t tmpfs -o size=256m tmpfs /dev/shm 2>/dev/null || true

# ---- Memory guard ----
/usr/local/bin/mem-guard.sh &

# ---- Clean old PID files ----
mkdir -p /run/xrdp /var/run/dbus
rm -f /run/xrdp/*.pid /var/run/dbus/pid

# ---- System DBus ----
dbus-daemon --system --fork || true

# ---- XRDP ----
xrdp-sesman
exec xrdp --nodaemon
