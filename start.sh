#!/bin/bash
set -e

# Create required directories
mkdir -p /run/dbus /run/xrdp
chown xrdp:xrdp /run/xrdp

# Start DBus
if ! pgrep -x dbus-daemon >/dev/null 2>&1; then
    dbus-daemon --system --fork
fi

# Start XRDP session manager
/usr/sbin/xrdp-sesman

# Start XRDP server
exec /usr/sbin/xrdp --nodaemon
