#!/usr/bin/env bash

echo "=== Starting XRDP Server on Railway ==="

# Railway ka port variable read karein (default 3389 agar railway port na de)
PORT="${PORT:-3389}"

# XRDP configuration mein port adjust kar sakte hain ya default 3389 use karein
echo "RDP Service is starting..."

# Background mein xrdp start karein
service xrdp start

# Container ko live rakhne ke liye
tail -f /var/log/xrdp.log
