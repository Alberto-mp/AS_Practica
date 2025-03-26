#!/bin/bash

set -e

echo "[NAS] Iniciando setup..."

# Instalación de herramientas necesarias
apt-get update && apt-get install -y isc-dhcp-client iputils-ping iproute2 cron rsync

# Elimina IP asignada por Docker
ip addr del $(hostname -i)/24 dev eth0 || true

# Obtener IP mediante DHCP
echo "[DHCP] Solicitando IP dinámica..."
dhclient -r eth0 && dhclient eth0
sleep 5  # Espera asignación DHCP

# Configurar rutas para otras redes
ip route add 172.30.0.0/24 via 172.20.0.2
ip route add 172.40.0.0/24 via 172.20.0.2

# Inicia Bind9 (DNS)
echo "[DNS] Iniciando Bind9..."
/usr/sbin/named -c /etc/bind/named.conf -g &

if [[ -x /etc/bind/update_zone.sh ]]; then
    echo "[DNS] Activando actualización dinámica de zona DNS..."
    while true; do
        /etc/bind/update_zone.sh
        sleep 30
    done &
else
    echo "[ERROR] update_zone.sh no encontrado o sin permisos"
fi

# Inicia Samba (NAS)
echo "[NAS] Iniciando Samba (smbd/nmbd)..."
mkdir -p /var/run/samba
service smbd start
service nmbd start

# Configurar cron para backups NAS
echo "[CRON] Configurando y arrancando cron..."
echo "0 2 * * * root /usr/bin/rsync -a /datos_origen/ /srv/nas/backups/" >> /etc/crontab
cron -f &

# Mantener contenedor activo
tail -f /dev/null




