FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# XFCE desktop, xrdp (RDP server), aur audio/sound utilities install karein
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-goodies \
    xrdp \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# XRDP user create karein (Password set karna zaroori hai)
RUN useradd -ms /bin/bash rdpuser && echo "rdpuser:password123" | chpasswd
RUN usermod -aG sudo rdpuser

WORKDIR /app
COPY . .

RUN chmod +x start.sh

# Railway ke liye port expose karein
EXPOSE 3389

CMD ["./start.sh"]
