#!/bin/bash

set -e

echo "[DNS] Iniciando Bind9..."
/usr/sbin/named -c /etc/bind/named.conf -g &

echo "[NAS] Iniciando smbd..."
mkdir -p /var/run/samba
smbd -D

echo "[CRON] Configurando y arrancando..."
echo "0 2 * * * root /usr/bin/rsync -a /datos_origen/ /srv/nas/backups/" >> /etc/crontab

cron -f



