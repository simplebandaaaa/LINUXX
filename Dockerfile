# syntax=docker/dockerfile:1
# Lightweight Win11-look XFCE desktop over xrdp - Railway Free plan (0.5 GB RAM) ke hisaab se
FROM ubuntu:24.04

# Wine nahi chahiye to Railway Variables mein WITH_WINE=0 set karo (image aur chhoti, RAM bhi bachti)
ARG WITH_WINE=1

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    NO_AT_BRIDGE=1 \
    GTK_A11Y=none

# ---- Firefox (snap nahi, real deb) Mozilla PPA se ---- #
RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common gnupg2 ca-certificates && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
        > /etc/apt/preferences.d/mozilla-firefox

# ---- Lean package list: XFCE ke sirf zaroori parts, koi extra plugin/app nahi ---- #
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
        dmz-cursor-theme && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# ---- Wine (optional, WITH_WINE=1 par) ---- #
RUN if [ "$WITH_WINE" = "1" ]; then \
        dpkg --add-architecture i386 && \
        apt-get update && \
        apt-get install -y --no-install-recommends wine wine32:i386 ; \
    fi && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man

# ---- User setup ---- #
# ubuntu:24.04 mein "ubuntu" user pehle se hota hai (uid 1000)
# Password image mein nahi hai, start.sh RDP_PASSWORD env variable se set karta hai.
RUN usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# ---- Rootless Xorg permission ---- #
RUN printf 'allowed_users=anybody\nneeds_root_rights=no\n' > /etc/X11/Xwrapper.config

# ---- xrdp tuning: kam RAM, kam bandwidth ---- #
# max_bpp=16: kam bandwidth (Railway egress paise leta hai). Behtar colours chahiye to 32 kar do.
# KillDisconnected: disconnect ke 5 min baad session band, RAM free ho jaati hai.
# Encryption default (strong) hi rakha hai, kyunki port public internet par hai.
RUN sed -i 's/^max_bpp=.*/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^#tcp_send_buffer_size=.*/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^MaxSessions=.*/MaxSessions=2/' /etc/xrdp/sesman.ini && \
    sed -i 's/^KillDisconnected=.*/KillDisconnected=true/' /etc/xrdp/sesman.ini && \
    sed -i 's/^DisconnectedTimeLimit=.*/DisconnectedTimeLimit=300/' /etc/xrdp/sesman.ini && \
    adduser xrdp ssl-cert

# ---- Bekaar autostart apps hatao (RAM bachti hai) ---- #
RUN rm -f /etc/xdg/autostart/*print* /etc/xdg/autostart/*blueman* \
          /etc/xdg/autostart/*screensaver* /etc/xdg/autostart/*power-manager* \
          /etc/xdg/autostart/*nm-applet* /etc/xdg/autostart/*pulse* \
          /etc/xdg/autostart/*geoclue* /etc/xdg/autostart/*at-spi* \
          /etc/xdg/autostart/*notifyd* /etc/xdg/autostart/*xfce4-clipman* || true

# ---- Firefox: smooth + crash-resistant setup ---- #
RUN <<'EOF'
set -e
mkdir -p /usr/lib/firefox/browser/defaults/preferences

# --- 1) Prefs: kam processes, kam memory, kam animation (RDP par smooth), crash ke baad tabs wapas ---
cat > /usr/lib/firefox/browser/defaults/preferences/lean.js <<'JS'
// --- Processes kam (har process = extra RAM) ---
pref("browser.preferences.defaultPerformanceSettings.enabled", false);
pref("dom.ipc.processCount", 1);
pref("dom.ipc.processCount.webIsolated", 1);
pref("dom.ipc.processPrelaunch.fission.number", 0);
pref("browser.tabs.remote.separatePrivilegedContentProcess", false);
pref("browser.tabs.remote.separatePrivilegedMozillaWebContentProcess", false);
pref("media.rdd-process.enabled", false);
pref("media.utility-process.enabled", false);
pref("layers.gpu-process.enabled", false);

// --- Memory limit ---
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

// --- Crash/kill ke baad tabs wapas, lekin ek-ek karke (ek saath load hone se RAM fatti hai) ---
pref("browser.startup.page", 3);
pref("browser.sessionstore.resume_from_crash", true);
pref("browser.sessionstore.restore_on_demand", true);
pref("browser.sessionstore.restore_pinned_tabs_on_demand", true);
pref("browser.sessionstore.interval", 15000);
pref("browser.sessionstore.max_tabs_undo", 3);
pref("browser.sessionstore.max_windows_undo", 1);
pref("browser.tabs.warnOnClose", false);

// --- RDP par smooth: kam frames, animation band ---
pref("layout.frame_rate", 30);
pref("general.smoothScroll", false);
pref("browser.tabs.animate", false);
pref("browser.fullscreen.animate", false);
pref("toolkit.cosmeticAnimations.enabled", false);
pref("ui.prefersReducedMotion", 1);
pref("browser.tabs.inTitlebar", 0);

// --- Background kaam band ---
pref("browser.startup.homepage", "about:blank");
pref("browser.newtabpage.enabled", false);
pref("browser.newtabpage.activity-stream.feeds.section.topstories", false);
pref("browser.newtabpage.activity-stream.feeds.topsites", false);
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

# --- 2) /usr/local/bin/firefox: PATH mein pehle aata hai, to saare launchers (panel, Start menu) ise chalate hain.
#        Normal close (exit 0) pe band; crash/kill pe 3 sec baad khud relaunch (tabs session-restore se wapas) ---
cat > /usr/local/bin/firefox <<'SH'
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
  if [ $((now - t0)) -gt 300 ]; then tries=0; t0=$now; fi
  tries=$((tries + 1))
  [ "$tries" -ge 5 ] && exit "$rc"
  sleep 3
  set --
done
SH

# --- 3) mem-guard: RAM 90% ke upar jaye to sabse bhari TAB process band karta hai (tab "crashed" dikhega, Reload karo),
#        taaki poora Firefox / desktop OOM killer ke haath na mare. Tab processes ko OOM killer ka pehla target bhi banata hai ---
cat > /usr/local/bin/mem-guard.sh <<'SH'
#!/bin/bash
get_mem() {
  LIMIT=""; USED=""
  if [ -r /sys/fs/cgroup/memory.max ] && [ -r /sys/fs/cgroup/memory.stat ]; then
    LIMIT=$(cat /sys/fs/cgroup/memory.max)
    USED=$(awk '$1=="anon"||$1=="shmem"{s+=$2} END{print s+0}' /sys/fs/cgroup/memory.stat)
  elif [ -r /sys/fs/cgroup/memory/memory.limit_in_bytes ] && [ -r /sys/fs/cgroup/memory/memory.stat ]; then
    LIMIT=$(cat /sys/fs/cgroup/memory/memory.limit_in_bytes)
    USED=$(awk '$1=="rss"||$1=="shmem"{s+=$2} END{print s+0}' /sys/fs/cgroup/memory/memory.stat)
  fi
}
last=0
while true; do
  for pid in $(pgrep -f -- '-contentproc.* tab$' 2>/dev/null); do
    echo 900 > /proc/$pid/oom_score_adj 2>/dev/null || true
  done
  get_mem
  if [[ "$LIMIT" =~ ^[0-9]+$ ]] && [ "$LIMIT" -gt 0 ] && [ "$LIMIT" -lt 100000000000 ] && [[ "$USED" =~ ^[0-9]+$ ]]; then
    pct=$(( USED * 100 / LIMIT ))
    now=$(date +%s)
    if [ "$pct" -ge 90 ] && [ $((now - last)) -ge 10 ]; then
      victim=$(ps -eo pid=,rss=,args= | awk '/-contentproc/ && / tab$/ {print $2, $1}' | sort -nr | head -1 | awk '{print $2}')
      if [ -n "$victim" ]; then
        kill -9 "$victim" 2>/dev/null || true
        last=$now
        echo "[mem-guard] memory ${pct}% - tab process $victim band kiya"
      fi
    fi
  fi
  sleep 3
done
SH

chmod +x /usr/local/bin/firefox /usr/local/bin/mem-guard.sh
EOF

# ---- Windows 11 look: theme + icons (repo URLs build se pehle ek baar check kar lena) ---- #
RUN git clone --depth=1 https://github.com/B00merang-Project/Windows-10 /usr/share/themes/Windows-10 && \
    git clone --depth=1 https://github.com/yeyushengfan258/Win11-icon-theme /tmp/win11-icons && \
    /tmp/win11-icons/install.sh -d /usr/share/icons && \
    rm -rf /tmp/win11-icons /usr/share/themes/Windows-10/.git

# ---- XFCE config: theme, icons, font, cursor, window buttons, taskbar ---- #
RUN <<'EOF'
set -e
CFG=/home/ubuntu/.config/xfce4
XML=$CFG/xfconf/xfce-perchannel-xml
mkdir -p "$XML" "$CFG/panel/launcher-2" "$CFG/panel/launcher-3" "$CFG/panel/launcher-4"

# Theme / icons / font / cursor
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

# Window manager: compositing OFF (lag aur RAM dono bachte hain), buttons right side, title left
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

# Taskbar: bottom, 44px, Start + Files + Firefox + Terminal + running apps + tray + clock
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
      <property name="items" type="array"><value type="string" value="thunar.desktop"/></property>
    </property>
    <property name="plugin-3" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="firefox.desktop"/></property>
    </property>
    <property name="plugin-4" type="string" value="launcher">
      <property name="items" type="array"><value type="string" value="xfce4-terminal.desktop"/></property>
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

# Launcher .desktop files
cp /usr/share/applications/thunar.desktop         "$CFG/panel/launcher-2/"
cp /usr/share/applications/firefox.desktop        "$CFG/panel/launcher-3/"
cp /usr/share/applications/xfce4-terminal.desktop "$CFG/panel/launcher-4/"

# Whisker menu = Start button
printf 'button-icon=start-here\nshow-button-title=false\n' > "$CFG/panel/whiskermenu-1.rc"

# xrdp session scripts (Xorg ke liye)
# MALLOC_ARENA_MAX=2: glibc ki memory fragmentation kam; cache /tmp mein taaki chhota volume na bhare
printf 'export XDG_CURRENT_DESKTOP=XFCE\nexport XDG_SESSION_DESKTOP=xfce\nexport MALLOC_ARENA_MAX=2\nexport XDG_CACHE_HOME=/tmp/.cache\n' > /home/ubuntu/.xsessionrc
printf 'unset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec startxfce4\n' > /home/ubuntu/.xsession
chmod +x /home/ubuntu/.xsession

chown -R ubuntu:ubuntu /home/ubuntu

# Volume /home/ubuntu par mount hua to ye configs chhup jayenge, isliye default copy rakhi hai.
# start.sh pehli baar ise volume mein copy kar deta hai.
cp -a /home/ubuntu /opt/ubuntu-home-defaults
EOF

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
