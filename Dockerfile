
# syntax=docker/dockerfile:1
FROM ubuntu:24.04

ARG WITH_WINE=1

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    NO_AT_BRIDGE=1 \
    GTK_A11Y=none \
    MALLOC_ARENA_MAX=2

# ---- Firefox Mozilla PPA ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common gnupg2 ca-certificates && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
    > /etc/apt/preferences.d/mozilla-firefox

# ---- XFCE Desktop + XRDP ----
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xfce4-session \
    xfwm4 \
    xfce4-panel \
    xfdesktop4 \
    xfce4-settings \
    xfce4-terminal \
    xfce4-whiskermenu-plugin \
    thunar \
    dbus-x11 \
    dbus-user-session \
    sudo \
    procps \
    git \
    ssl-cert \
    firefox \
    fonts-noto-core \
    fonts-inter \
    gtk2-engines-murrine \
    gnome-themes-extra \
    adwaita-icon-theme \
    dmz-cursor-theme \
    xfconf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# ---- Optional Wine ----
RUN if [ "$WITH_WINE" = "1" ]; then \
    dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y --no-install-recommends wine wine32:i386; \
    fi && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# ---- Ubuntu User ----
RUN usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# ---- Xorg Permission ----
RUN printf 'allowed_users=anybody\nneeds_root_rights=no\n' \
    > /etc/X11/Xwrapper.config

# ---- XRDP Optimization ----
RUN sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^#tcp_send_buffer_size=.*/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^MaxSessions=.*/MaxSessions=2/' /etc/xrdp/sesman.ini && \
    sed -i 's/^KillDisconnected=.*/KillDisconnected=true/' /etc/xrdp/sesman.ini && \
    sed -i 's/^DisconnectedTimeLimit=.*/DisconnectedTimeLimit=300/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

# ---- Remove Unnecessary Autostart Apps ----
RUN rm -f /etc/xdg/autostart/*print* \
    /etc/xdg/autostart/*blueman* \
    /etc/xdg/autostart/*screensaver* \
    /etc/xdg/autostart/*power-manager* \
    /etc/xdg/autostart/*nm-applet* \
    /etc/xdg/autostart/*pulse* \
    /etc/xdg/autostart/*geoclue* \
    /etc/xdg/autostart/*at-spi* \
    /etc/xdg/autostart/*notifyd* \
    /etc/xdg/autostart/*xfce4-clipman* || true

# ---- Firefox Optimization ----
RUN mkdir -p /usr/lib/firefox/browser/defaults/preferences && \
    cat > /usr/lib/firefox/browser/defaults/preferences/lean.js <<'JS'
pref("browser.preferences.defaultPerformanceSettings.enabled", false);
pref("dom.ipc.processCount", 1);
pref("dom.ipc.processCount.webIsolated", 1);
pref("dom.ipc.processPrelaunch.fission.number", 0);
pref("media.rdd-process.enabled", false);
pref("media.utility-process.enabled", false);
pref("layers.gpu-process.enabled", false);

pref("browser.cache.disk.enable", false);
pref("browser.cache.memory.enable", true);
pref("browser.cache.memory.capacity", 16384);
pref("browser.sessionhistory.max_total_viewers", 0);
pref("browser.tabs.unloadOnLowMemory", true);
pref("javascript.options.mem.high_water_mark", 32);
pref("image.mem.surfacecache.max_size_kb", 65536);
pref("image.mem.max_decoded_image_kb", 51200);

pref("webgl.disabled", true);
pref("gfx.canvas.accelerated", false);
pref("layers.acceleration.disabled", true);
pref("gfx.webrender.software", true);
pref("media.hardware-video-decoding.enabled", false);
pref("media.autoplay.default", 5);

pref("browser.startup.page", 3);
pref("browser.sessionstore.resume_from_crash", true);
pref("browser.sessionstore.restore_on_demand", true);
pref("browser.sessionstore.restore_pinned_tabs_on_demand", true);
pref("browser.sessionstore.interval", 15000);
pref("browser.sessionstore.max_tabs_undo", 3);
pref("browser.sessionstore.max_windows_undo", 1);

pref("layout.frame_rate", 30);
pref("general.smoothScroll", false);
pref("browser.tabs.animate", false);
pref("browser.fullscreen.animate", false);
pref("toolkit.cosmeticAnimations.enabled", false);
pref("ui.prefersReducedMotion", 1);

pref("browser.startup.homepage", "about:blank");
pref("browser.newtabpage.enabled", false);
pref("browser.discovery.enabled", false);
pref("app.update.auto", false);
pref("app.normandy.enabled", false);
pref("toolkit.telemetry.enabled", false);
pref("datareporting.healthreport.uploadEnabled", false);
pref("extensions.pocket.enabled", false);
pref("dom.webnotifications.enabled", false);
pref("dom.push.enabled", false);
pref("network.prefetch-next", false);
pref("network.dns.disablePrefetch", true);
pref("network.predictor.enabled", false);
JS

# ---- Firefox Crash Recovery Wrapper ----
RUN cat > /usr/local/bin/firefox <<'SH'
#!/bin/bash
export MOZ_DISABLE_CONTENT_SANDBOX=1
FF=/usr/bin/firefox
tries=0
t0=$(date +%s)

while true; do
    "$FF" "$@"
    rc=$?

    [ "$rc" -eq 0 ] && exit 0

    now=$(date +%s)
    if [ $((now-t0)) -gt 300 ]; then
        tries=0
        t0=$now
    fi

    tries=$((tries+1))
    [ "$tries" -ge 5 ] && exit "$rc"

    sleep 3
    set --
done
SH

# ---- RAM Memory Guard ----
RUN cat > /usr/local/bin/mem-guard.sh <<'SH'
#!/bin/bash

last=0

while true; do
    LIMIT=""
    USED=""

    if [ -r /sys/fs/cgroup/memory.max ]; then
        LIMIT=$(cat /sys/fs/cgroup/memory.max)
        USED=$(awk '$1=="anon"||$1=="shmem"{s+=$2} END{print s+0}' /sys/fs/cgroup/memory.stat)
    elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ]; then
        LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
        USED=$(awk '$1=="rss"||$1=="shmem"{s+=$2} END{print s+0}' /sys/fs/cgroup/memory/memory.stat)
    fi

    if [[ "$LIMIT" =~ ^[0-9]+$ ]] && \
       [[ "$USED" =~ ^[0-9]+$ ]] && \
       [ "$LIMIT" -gt 0 ] && [ "$LIMIT" -lt 100000000000 ]; then

        pct=$((USED*100/LIMIT))
        now=$(date +%s)

        for pid in $(pgrep -f -- '-contentproc.* tab$' 2>/dev/null); do
            echo 900 > /proc/$pid/oom_score_adj 2>/dev/null || true
        done

        if [ "$pct" -ge 90 ] && [ $((now-last)) -ge 10 ]; then
            victim=$(ps -eo pid=,rss=,args= | \
                awk '/-contentproc/ && / tab$/ {print $2, $1}' | \
                sort -nr | head -1 | awk '{print $2}')

            if [ -n "$victim" ]; then
                kill -9 "$victim" 2>/dev/null || true
                last=$now
                echo "[mem-guard] Memory ${pct}% - tab $victim killed"
            fi
        fi
    fi

    sleep 3
done
SH

RUN chmod +x /usr/local/bin/firefox /usr/local/bin/mem-guard.sh

# ---- Windows 11 Theme and Icons ----
RUN git clone --depth=1 \
    https://github.com/B00merang-Project/Windows-10 \
    /usr/share/themes/Windows-10 && \
    git clone --depth=1 \
    https://github.com/yeyushengfan258/Win11-icon-theme \
    /tmp/win11-icons && \
    /tmp/win11-icons/install.sh -d /usr/share/icons && \
    rm -rf /tmp/win11-icons /usr/share/themes/Windows-10/.git

# ---- Permanent Umesh Editz Wallpaper ----
RUN mkdir -p /usr/share/backgrounds

COPY ["Umesh Editz Crowned Channel Logo.png", "/usr/share/backgrounds/umesheditz-wallpaper.png"]

RUN cat > /usr/local/bin/set-wallpaper.sh <<'SH'
#!/bin/bash

WALL="/usr/share/backgrounds/umesheditz-wallpaper.png"

# Wait for XFCE desktop
for i in $(seq 1 30); do
    if pgrep -x xfdesktop >/dev/null 2>&1; then
        break
    fi
    sleep 2
done

# Apply wallpaper to available XFCE workspaces
PROPS=$(xfconf-query -c xfce4-desktop -l 2>/dev/null | grep '/last-image$' || true)

if [ -n "$PROPS" ]; then
    while IFS= read -r prop; do
        base="${prop%/last-image}"

        xfconf-query -c xfce4-desktop \
            -p "$prop" -s "$WALL"

        xfconf-query -c xfce4-desktop \
            -p "$base/image-style" --create -t int -s 5
    done <<< "$PROPS"
else
    xfconf-query -c xfce4-desktop \
        -p /backdrop/screen0/monitor0/workspace0/last-image \
        --create -t string -s "$WALL"

    xfconf-query -c xfce4-desktop \
        -p /backdrop/screen0/monitor0/workspace0/image-style \
        --create -t int -s 5
fi

xfdesktop --reload 2>/dev/null || true
SH

RUN chmod +x /usr/local/bin/set-wallpaper.sh

# ---- XFCE Desktop Configuration ----
RUN <<'EOF'
set -e

CFG=/home/ubuntu/.config/xfce4
XML=$CFG/xfconf/xfce-perchannel-xml

mkdir -p "$XML" \
    "$CFG/panel/launcher-2" \
    "$CFG/panel/launcher-3" \
    "$CFG/panel/launcher-4"

# Theme and icons
cat > "$XML/xsettings.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xsettings" version="1.0">
  <property name="Net" type="empty">
    <property name="ThemeName" type="string" value="Windows-10"/>
    <property name="IconThemeName" type="string" value="Win11"/>
  </property>
  <property name="Gtk" type="empty">
    <property name="FontName" type="string" value="Inter 10"/>
    <property name="CursorThemeName" type="string" value="DMZ-White"/>
  </property>
  <property name="Xft" type="empty">
    <property name="Antialias" type="int" value="1"/>
    <property name="HintStyle" type="string" value="hintslight"/>
    <property name="RGBA" type="string" value="rgb"/>
  </property>
</channel>
XML

# Window manager
cat > "$XML/xfwm4.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfwm4" version="1.0">
  <property name="general" type="empty">
    <property name="use_compositing" type="bool" value="false"/>
    <property name="theme" type="string" value="Windows-10"/>
    <property name="title_alignment" type="string" value="left"/>
    <property name="button_layout" type="string" value="|HMC"/>
  </property>
</channel>
XML

# Bottom taskbar
cat > "$XML/xfce4-panel.xml" <<'XML'
<?xml version="1.0" encoding="UTF-8"?>
<channel name="xfce4-panel" version="1.0">
  <property name="configver" type="int" value="2"/>
  <property name="panels" type="array">
    <value type="int" value="1"/>
    <property name="panel-1" type="empty">
      <property name="position" type="string" value="p=8;x=0;y=0"/>
      <property name="length" type="uint" value="100"/>
      <property name="position-locked" type="bool" value="true"/>
      <property name="size" type="uint" value="44"/>
      <property name="icon-size" type="uint" value="24"/>
      <property name="plugin-ids" type="array">
        <value type="int" value="1"/>
        <value type="int" value="2"/>
        <value type="int" value="3"/>
        <value type="int" value="4"/>
        <value type="int" value="5"/>
        <value type="int" value="6"/>
        <value type="int" value="7"/>
        <value type="int" value="9"/>
      </property>
    </property>
  </property>

  <property name="plugins" type="empty">
    <property name="plugin-1" type="string" value="whiskermenu"/>
    <property name="plugin-2" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="thunar.desktop"/>
      </property>
    </property>
    <property name="plugin-3" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="firefox.desktop"/>
      </property>
    </property>
    <property name="plugin-4" type="string" value="launcher">
      <property name="items" type="array">
        <value type="string" value="xfce4-terminal.desktop"/>
      </property>
    </property>
    <property name="plugin-5" type="string" value="tasklist">
      <property name="grouping" type="uint" value="0"/>
      <property name="show-labels" type="bool" value="false"/>
    </property>
    <property name="plugin-6" type="string" value="separator">
      <property name="style" type="uint" value="0"/>
      <property name="expand" type="bool" value="true"/>
    </property>
    <property name="plugin-7" type="string" value="systray"/>
    <property name="plugin-9" type="string" value="clock">
      <property name="mode" type="uint" value="2"/>
      <property name="digital-time-format" type="string" value="%I:%M %p"/>
      <property name="digital-date-format" type="string" value="%d/%m/%Y"/>
    </property>
  </property>
</channel>
XML

# Launcher files
cp /usr/share/applications/thunar.desktop "$CFG/panel/launcher-2/"
cp /usr/share/applications/firefox.desktop "$CFG/panel/launcher-3/"
cp /usr/share/applications/xfce4-terminal.desktop "$CFG/panel/launcher-4/"

printf 'button-icon=start-here\nshow-button-title=false\n' \
    > "$CFG/panel/whiskermenu-1.rc"

# Xsession
printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nexport MALLOC_ARENA_MAX=2\nexport XDG_CACHE_HOME=/tmp/.cache\n' \
    > /home/ubuntu/.xsessionrc

printf 'unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec startxfce4\n' \
    > /home/ubuntu/.xsession

chmod +x /home/ubuntu/.xsession

chown -R ubuntu:ubuntu /home/ubuntu

# Save default home
cp -a /home/ubuntu /opt/ubuntu-home-defaults
EOF

# ---- Wallpaper autostart ----
RUN mkdir -p /etc/xdg/autostart && \
    cat > /etc/xdg/autostart/umesheditz-wallpaper.desktop <<'EOF'
[Desktop Entry]
Type=Application
Name=Umesh Editz Wallpaper
Exec=/usr/local/bin/set-wallpaper.sh
OnlyShowIn=XFCE;
Terminal=false
Hidden=false
EOF

# ---- Startup Script ----
COPY start.sh /start.sh

# Fix CRLF and permissions
RUN sed -i 's/\r$//' /start.sh && \
    chmod 755 /start.sh

EXPOSE 3389

# IMPORTANT: Run using Bash to prevent Exec format error
CMD ["/bin/bash", "/start.sh"]
