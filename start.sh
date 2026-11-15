
#!/bin/bash
set -e

echo "================================"
echo "       WINUX 11 DESKTOP"
echo "================================"

# Start D-Bus system service
mkdir -p /run/dbus

if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system --fork
fi

# Prepare XRDP
mkdir -p /run/xrdp
chown xrdp:xrdp /run/xrdp

# Ensure certificate permissions
adduser xrdp ssl-cert >/dev/null 2>&1 || true

# Start XRDP session manager
/usr/sbin/xrdp-sesman

echo "XRDP Session Manager started"

# Start XRDP server in foreground
echo "Starting Remote Desktop on port 3389"

exec /usr/sbin/xrdp --nodaemon
