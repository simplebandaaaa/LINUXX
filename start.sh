
#!/bin/bash
set -e

echo "Starting Winux 11 Desktop..."

# Start D-Bus
mkdir -p /run/dbus
if ! pgrep -x dbus-daemon >/dev/null; then
    dbus-daemon --system --fork
fi

# Create XRDP runtime directories
mkdir -p /var/run/xrdp
chown xrdp:xrdp /var/run/xrdp

# Start XRDP services
/usr/sbin/xrdp-sesman
/usr/sbin/xrdp --nodaemon &
XRDP_PID=$!

# Configure XFCE for Windows 11 style
mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml

# Center-style panel configuration
cat > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfce4-panel.xml <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
 <property name="panels" type="array">
  <value type="int" value="1"/>
  <property name="panel-1" type="empty">
   <property name="position" type="string" value="p=8;x=960;y=1040"/>
   <property name="length" type="uint" value="85"/>
   <property name="position-locked" type="bool" value="true"/>
   <property name="size" type="uint" value="46"/>
   <property name="plugin-ids" type="array">
    <value type="int" value="1"/>
    <value type="int" value="2"/>
    <value type="int" value="3"/>
    <value type="int" value="4"/>
   </property>
  </property>
 </property>
 <property name="plugins" type="empty">
  <property name="plugin-1" type="string" value="whiskermenu"/>
  <property name="plugin-2" type="string" value="tasklist"/>
  <property name="plugin-3" type="string" value="separator"/>
  <property name="plugin-4" type="string" value="systray"/>
 </property>
</channel>
EOF

# Permissions
chown -R ubuntu:ubuntu /home/ubuntu

echo "Winux 11 Desktop is ready!"
echo "Connect using RDP on port 3389"

# Keep container alive
wait $XRDP_PID
