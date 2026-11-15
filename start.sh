
#!/bin/bash
set -e

# Create runtime directories
mkdir -p /run/dbus /run/xrdp
chown xrdp:xrdp /run/xrdp

# Start system DBus
dbus-daemon --system --fork

# Start XRDP session manager
/usr/sbin/xrdp-sesman

# Start XRDP server
exec /usr/sbin/xrdp --nodaemon
