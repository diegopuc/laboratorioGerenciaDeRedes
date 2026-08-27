#!/usr/bin/env bash
set -e

LAB_HOSTNAME="${LAB_HOSTNAME:-arch-lab}"
LAB_ROLE="${LAB_ROLE:-Servidor Linux}"
LAB_LOCATION="${LAB_LOCATION:-Laboratorio}"

mkdir -p /etc/zabbix/zabbix_agentd.conf.d
cat > /etc/zabbix/zabbix_agentd.conf <<EOF
PidFile=/tmp/zabbix_agentd.pid
LogType=console
Server=zabbix-server,172.28.0.0/24
ServerActive=zabbix-server:10051
Hostname=${LAB_HOSTNAME}
Timeout=10
Include=/etc/zabbix/zabbix_agentd.conf.d/*.conf
EOF

mkdir -p /etc/snmp
cat > /etc/snmp/snmpd.conf <<EOF
agentAddress udp:161
rocommunity labpublic 172.28.0.0/24
sysLocation ${LAB_LOCATION}
sysContact Gerencia de Redes
sysName ${LAB_HOSTNAME}
EOF

sed \
  -e "s/{{HOSTNAME}}/${LAB_HOSTNAME}/g" \
  -e "s/{{ROLE}}/${LAB_ROLE}/g" \
  -e "s/{{LOCATION}}/${LAB_LOCATION}/g" \
  /opt/lab/index.html > /usr/share/nginx/html/index.html

nginx
snmpd -f -Lo -C -c /etc/snmp/snmpd.conf &
exec /usr/bin/zabbix_agentd -f
