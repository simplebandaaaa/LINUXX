#!/bin/bash
set -e

PORT="${PORT:-3389}"

mkdir -p /run/dbus /run/xrdp
chown xrdp:xrdp /run/xrdp

dbus-daemon --system --fork

# Configure XRDP
sed -i "s/^port=.*/port=0.0.0.0:${PORT}/" /etc/xrdp/xrdp.ini

# Start session manager
/usr/sbin/xrdp-sesman

# Start XRDP
exec /usr/sbin/xrdp --nodaemon
