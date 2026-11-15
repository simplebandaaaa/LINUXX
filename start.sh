#!/bin/bash
set -e

PORT="${PORT:-3389}"

mkdir -p /run/dbus /run/xrdp
chown xrdp:xrdp /run/xrdp

# Start DBus
dbus-daemon --system --fork

# Configure XRDP port
sed -i "s/^port=.*/port=0.0.0.0:${PORT}/" /etc/xrdp/xrdp.ini

# Start XRDP session manager
/usr/sbin/xrdp-sesman

# Start XRDP server
exec /usr/sbin/xrdp --nodaemon
