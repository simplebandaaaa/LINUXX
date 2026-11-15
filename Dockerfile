
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Kolkata

# Install desktop and XRDP packages
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    xorgxrdp \
    dbus \
    dbus-x11 \
    dbus-user-session \
    sudo \
    curl \
    wget \
    git \
    firefox \
    wine \
    wine32:i386 \
    fonts-liberation \
    fonts-noto \
    x11-xserver-utils \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create and configure ubuntu user
RUN if ! id ubuntu >/dev/null 2>&1; then \
        useradd -m -s /bin/bash ubuntu; \
    fi && \
    usermod -s /bin/bash ubuntu && \
    echo "ubuntu:ubuntu" | chpasswd && \
    usermod -aG sudo ubuntu && \
    printf 'ubuntu ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/ubuntu && \
    chmod 0440 /etc/sudoers.d/ubuntu

# Install Windows 11 style theme
RUN git clone --depth 1 \
    https://github.com/yeyushengfan258/Win11-gtk-theme.git \
    /tmp/Win11-gtk-theme && \
    cd /tmp/Win11-gtk-theme && \
    ./install.sh -d /usr/share/themes -n Win11 -c light -s standard --tweaks solid && \
    rm -rf /tmp/Win11-gtk-theme

# Configure XFCE session
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec dbus-launch --exit-with-session startxfce4\n' \
    > /home/ubuntu/.xsession && \
    chown ubuntu:ubuntu /home/ubuntu/.xsession && \
    chmod +x /home/ubuntu/.xsession

# Configure XRDP startup
RUN printf '#!/bin/sh\nunset DBUS_SESSION_BUS_ADDRESS\nunset XDG_RUNTIME_DIR\nexec dbus-launch --exit-with-session startxfce4\n' \
    > /etc/xrdp/startwm.sh && \
    chmod +x /etc/xrdp/startwm.sh

# Configure XRDP
RUN sed -i 's/^port=.*/port=3389/' /etc/xrdp/xrdp.ini && \
    sed -i 's/^#\?address=.*/address=0.0.0.0/' /etc/xrdp/xrdp.ini && \
    adduser xrdp ssl-cert && \
    chown -R ubuntu:ubuntu /home/ubuntu

COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 3389

CMD ["/start.sh"]
