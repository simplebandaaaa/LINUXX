#!/bin/bash
set -e

# ---- Password: Railway Variables mein RDP_PASSWORD set karoge to wahi chalega, warna ye default ---- #
RDP_PASSWORD="${RDP_PASSWORD:-umeshedittz123}"
echo "ubuntu:${RDP_PASSWORD}" | chpasswd

# ---- Volume /home/ubuntu par mount ho to pehli baar defaults copy karo ---- #
if [ ! -e /home/ubuntu/.xsession ]; then
  cp -a /opt/ubuntu-home-defaults/. /home/ubuntu/
fi
chown ubuntu:ubuntu /home/ubuntu

# ---- /dev/shm 256 MB (Firefox ke liye). Railway mein permission na mile to chup-chaap skip ---- #
mount -t tmpfs -o size=256m tmpfs /dev/shm 2>/dev/null || true

# ---- Memory guard (Firefox ko desktop se pehle qurbaan karta hai) ---- #
/usr/local/bin/mem-guard.sh &

# ---- Purane pid files hatao (restart pe xrdp start na hone ki problem) ---- #
mkdir -p /run/xrdp /var/run/dbus
rm -f /run/xrdp/*.pid /var/run/dbus/pid

# ---- System dbus ---- #
dbus-daemon --system --fork || true

# ---- xrdp (foreground mein, taaki container chalta rahe) ---- #
xrdp-sesman
exec xrdp --nodaemon
