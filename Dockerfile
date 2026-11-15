
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# Install XFCE, XRDP and Xorg dependencies
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xfce4-session \
    xfce4-panel \
    xfwm4 \
    xrdp \
    xorgxrdp \
    xserver-xorg-core \
    xauth \
    x11-xserver-utils \
    xfonts-base \
    dbus \
    dbus-x11 \
    sudo \
    curl \
    wget \
    git \
    firefox \
    wine \
    wine32:i386 \
    fonts-liberation \
    fonts-noto \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Configure ubuntu user
RUN if ! id ubuntu >/dev/null 2>&1; then \
        useradd -m -s /bin/bash ubuntu; \
    fi && \
    usermod -s /bin/bash ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu && \
    mkdir -p /home/ubuntu && \
    chown -R ubuntu:ubuntu /home/ubuntu

# Install Windows 11 GTK theme
RUN git clone --depth 1 \
    https://github.com/yeyushengfan258/Win11-gtk-theme.git \
    /tmp/Win11-gtk-theme && \
    cd /tmp/Win11-gtk-theme && \
    ./install.sh -d /usr/share/themes -n Win11 -c light -s standard --tweaks solid && \
    rm -rf /tmp/Win11-gtk-theme

# Configure XFCE session
RUN printf '%s\n' \
    '#!/bin/sh' \
    'unset DBUS_SESSION_BUS_ADDRESS' \
    'unset XDG_RUNTIME_DIR' \
    'exec dbus-launch --exit-with-session startxfce4' \
    > /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession && \
    chown ubuntu:ubuntu /home/ubuntu/.xsession

# Keep the standard XRDP startup script
RUN adduser xrdp ssl-cert && \
    sed -i 's/^port=.*/port=3389/' /etc/xrdp/xrdp.ini

# Copy startup script
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
