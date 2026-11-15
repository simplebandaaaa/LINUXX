
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV DISPLAY=:10

# Enable 32-bit architecture for Wine
RUN dpkg --add-architecture i386

# Install Mozilla Firefox repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    gnupg2 && \
    add-apt-repository -y ppa:mozillateam/ppa

# Firefox package priority
RUN printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
    > /etc/apt/preferences.d/mozilla-firefox

# Install Desktop and applications
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xfce4 \
    xfce4-panel \
    xfce4-whiskermenu-plugin \
    xfce4-session \
    xfce4-settings \
    xfce4-terminal \
    xfdesktop4 \
    xfwm4 \
    dbus-x11 \
    dbus-user-session \
    sudo \
    curl \
    wget \
    git \
    unzip \
    sassc \
    gtk2-engines-murrine \
    gnome-themes-extra \
    papirus-icon-theme \
    fonts-crosextra-carlito \
    ssl-cert \
    wine \
    wine32:i386 \
    firefox \
    procps \
    x11-xserver-utils && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Windows 11 GTK theme
RUN git clone --depth 1 \
    https://github.com/yeyushengfan258/Win11-gtk-theme.git \
    /tmp/Win11-gtk-theme && \
    cd /tmp/Win11-gtk-theme && \
    chmod +x install.sh && \
    ./install.sh \
    -d /usr/share/themes \
    -n Win11 \
    -c light \
    -s standard \
    --tweaks solid && \
    rm -rf /tmp/Win11-gtk-theme

# Setup ubuntu user (safe if already exists)
RUN if ! id ubuntu >/dev/null 2>&1; then \
        useradd -m -s /bin/bash ubuntu; \
    fi && \
    mkdir -p /home/ubuntu && \
    usermod -d /home/ubuntu -s /bin/bash ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' \
    > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# Xorg configuration
RUN mkdir -p /etc/X11 && \
    printf 'allowed_users=anybody\nneeds_root_rights=no\n' \
    > /etc/X11/Xwrapper.config

# XRDP configuration
RUN adduser xrdp ssl-cert && \
    mkdir -p /run/xrdp && \
    chown xrdp:xrdp /run/xrdp

# Disable XFCE compositing
RUN mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' \
    > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# Configure Win11 appearance
RUN mkdir -p /home/ubuntu/.config/xfce4 && \
    printf '#!/bin/bash\n\
export XDG_CURRENT_DESKTOP=XFCE\n\
export XDG_SESSION_DESKTOP=xfce\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
exec dbus-launch --exit-with-session startxfce4\n' \
    > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Startup script
COPY start.sh /start.sh

RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
