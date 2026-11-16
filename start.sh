#!/bin/bash
set -e

# ---- Password: Railway Variables mein RDP_PASSWORD set karo ---- #
if [ -z "${RDP_PASSWORD}" ]; then
  RDP_PASSWORD="$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 16)"
  echo "=============================================================="
  echo "RDP_PASSWORD set nahi tha. Is baar ka random password:"
  echo "  user: ubuntu   password: ${RDP_PASSWORD}"
  echo "Pakka password rakhne ke liye Railway Variables mein RDP_PASSWORD daalo."
  echo "=============================================================="
fi
echo "ubuntu:${RDP_PASSWORD}" | chpasswd

# ---- Volume /home/ubuntu par mount ho to pehli baar defaults copy karo ---- #
if [ ! -e /home/ubuntu/.xsession ]; then
  cp -a /opt/ubuntu-home-defaults/. /home/ubuntu/
fi
chown ubuntu:ubuntu /home/ubuntu

# ---- /dev/shm 256 MB (Firefox ke liye). Railway mein permission na mile to chup-chaap skip ---- #
mount -t tmpfs -o size=256m tmpfs /dev/shm 2>/dev/null || true

# ---- Purane pid files hatao (restart pe xrdp start na hone ki problem) ---- #
mkdir -p /run/xrdp /var/run/dbus
rm -f /run/xrdp/*.pid /var/run/dbus/pid

# ---- System dbus ---- #
dbus-daemon --system --fork || true

# ---- xrdp (foreground mein, taaki container chalta rahe) ---- #
xrdp-sesman
exec xrdp --nodaemon
