FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture
RUN dpkg --add-architecture i386

# Firefox repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg2 && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
    > /etc/apt/preferences.d/mozilla-firefox

# Desktop and XRDP packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xfce4 \
    xfce4-panel \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfdesktop4 \
    xfwm4 \
    xfce4-whiskermenu-plugin \
    dbus \
    dbus-x11 \
    dbus-user-session \
    sudo \
    curl \
    wget \
    git \
    unzip \
    procps \
    iproute2 \
    ssl-cert \
    sassc \
    gtk2-engines-murrine \
    gnome-themes-extra \
    papirus-icon-theme \
    wine \
    wine32:i386 \
    firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Windows 11 GTK theme
RUN git clone --depth 1 \
    https://github.com/yeyushengfan258/Win11-gtk-theme.git \
    /tmp/Win11-gtk-theme && \
    cd /tmp/Win11-gtk-theme && \
    chmod +x install.sh && \
    ./install.sh -d /usr/share/themes -n Win11 \
    -c light -s standard --tweaks solid && \
    rm -rf /tmp/Win11-gtk-theme

# Setup user safely
RUN if ! id ubuntu >/dev/null 2>&1; then \
        useradd -m -s /bin/bash ubuntu; \
    fi && \
    usermod -s /bin/bash ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' \
    > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# Xorg configuration
RUN mkdir -p /etc/X11 && \
    printf 'allowed_users=anybody\nneeds_root_rights=no\n' \
    > /etc/X11/Xwrapper.config

# XRDP permissions
RUN adduser xrdp ssl-cert || true && \
    mkdir -p /run/dbus /run/xrdp && \
    chown xrdp:xrdp /run/xrdp

# XFCE Windows-like theme settings
RUN mkdir -p \
    /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' \
    > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml && \
    printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec dbus-run-session -- startxfce4\n' \
    > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    chown -R ubuntu:ubuntu /home/ubuntu

# XRDP port
EXPOSE 3389

# Startup
COPY start.sh /start.sh
RUN chmod +x /start.sh

CMD ["/start.sh"]
