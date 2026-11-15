
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Enable 32-bit architecture
RUN dpkg --add-architecture i386

# Firefox Mozilla PPA
RUN apt-get update && apt-get install -y --no-install-recommends \
    software-properties-common gnupg2 && \
    add-apt-repository -y ppa:mozillateam/ppa && \
    printf 'Package: firefox*\nPin: release o=LP-PPA-mozillateam\nPin-Priority: 1001\n' \
    > /etc/apt/preferences.d/mozilla-firefox

# Desktop, XRDP, Wine and theme dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xfce4 \
    xfce4-panel \
    xfce4-whiskermenu-plugin \
    xfwm4 \
    xfce4-settings \
    xfce4-session \
    xfce4-terminal \
    xfdesktop4 \
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
    firefox && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Windows 11 GTK Theme
RUN git clone --depth 1 \
    https://github.com/yeyushengfan258/Win11-gtk-theme.git \
    /tmp/Win11-gtk-theme && \
    cd /tmp/Win11-gtk-theme && \
    chmod +x install.sh && \
    ./install.sh -d /usr/share/themes -n Win11 \
    -t blue -c light -s standard --tweaks solid && \
    rm -rf /tmp/Win11-gtk-theme

# Create Ubuntu user
RUN useradd -m -s /bin/bash ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Xorg permissions
RUN mkdir -p /etc/X11 && \
    printf 'allowed_users=anybody\nneeds_root_rights=no\n' \
    > /etc/X11/Xwrapper.config

# XRDP settings
RUN sed -i 's/crypt_level=high/crypt_level=low/' /etc/xrdp/xrdp.ini && \
    sed -i 's/security_layer=negotiate/security_layer=rdp/' /etc/xrdp/xrdp.ini && \
    sed -i 's/max_bpp=32/max_bpp=16/' /etc/xrdp/xrdp.ini && \
    sed -i 's/#tcp_send_buffer_size=32768/tcp_send_buffer_size=131072/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert

# Disable XFCE compositing
RUN mkdir -p /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml && \
    printf '<?xml version="1.0" encoding="UTF-8"?>\n<channel name="xfwm4" version="1.0"><property name="general" type="empty"><property name="use_compositing" type="bool" value="false"/></property></channel>' \
    > /home/ubuntu/.config/xfce4/xfconf/xfce-perchannel-xml/xfwm4.xml

# Windows 11 inspired desktop settings
RUN printf '#!/bin/bash\n\
export XDG_CURRENT_DESKTOP=XFCE\n\
export XDG_SESSION_DESKTOP=xfce\n\
unset DBUS_SESSION_BUS_ADDRESS\n\
unset XDG_RUNTIME_DIR\n\
xfconf-query -c xsettings -p /Net/ThemeName -s Win11 || xfconf-query -c xsettings -p /Net/ThemeName -n -t string -s Win11\n\
xfconf-query -c xsettings -p /Net/IconThemeName -s Papirus || xfconf-query -c xsettings -p /Net/IconThemeName -n -t string -s Papirus\n\
xfconf-query -c xfwm4 -p /general/theme -s Win11 || xfconf-query -c xfwm4 -p /general/theme -n -t string -s Win11\n\
exec startxfce4\n' > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    cp /home/ubuntu/.xsession /home/ubuntu/.xsessionrc && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
