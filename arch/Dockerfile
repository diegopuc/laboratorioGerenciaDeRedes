FROM archlinux:latest

RUN pacman -Syu --noconfirm \
    zabbix-agent \
    net-snmp \
    nginx \
    iproute2 \
    iputils \
    procps-ng \
    curl \
    && pacman -Scc --noconfirm

COPY start.sh /usr/local/bin/start-lab.sh
COPY index.html /opt/lab/index.html

RUN chmod +x /usr/local/bin/start-lab.sh \
    && mkdir -p /run/nginx /opt/lab

EXPOSE 80 10050 161/udp

ENTRYPOINT ["/usr/local/bin/start-lab.sh"]
