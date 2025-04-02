#!/bin/bash

set -e

echo "[NAS] Iniciando setup..."
apt-get update && apt-get install -y wget gnupg 
apt-get install -y default-mysql-client

# Añadir repositorio oficial de PostgreSQL
echo "deb http://apt.postgresql.org/pub/repos/apt bookworm-pgdg main" > /etc/apt/sources.list.d/pgdg.list
wget -qO - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Instalar herramientas necesarias
apt-get update && apt-get install -y \
  isc-dhcp-client \
  iputils-ping \
  iproute2 \
  cron \
  rsync \
  postgresql-client-17

# Eliminar IP asignada por Docker si existe
ip addr del $(hostname -i)/24 dev eth0 || true

# Obtener IP mediante DHCP
echo "[DHCP] Solicitando IP dinámica..."
dhclient -r eth0 && dhclient eth0
sleep 5

# Configurar rutas para otras redes
ip route add 172.30.0.0/24 via 172.20.0.2 || true
ip route add 172.40.0.0/24 via 172.20.0.2 || true

# Inicia Bind9 (DNS)
echo "[DNS] Iniciando Bind9..."
/usr/sbin/named -c /etc/bind/named.conf -g &

# Actualización dinámica de zonas
if [[ -x /etc/bind/update_zone.sh ]]; then
  echo "[DNS] Activando actualización dinámica de zona DNS..."
  while true; do
    /etc/bind/update_zone.sh
    sleep 30
  done &
else
  echo "[ERROR] update_zone.sh no encontrado o sin permisos"
fi

# Iniciar Samba (NAS)
echo "[NAS] Iniciando Samba (smbd/nmbd)..."
mkdir -p /var/run/samba
echo "[NAS] Configurando usuario Samba..."
useradd -M -s /sbin/nologin admin || true
(echo "naspass"; echo "naspass") | smbpasswd -a admin
service smbd start
service nmbd start

# Iniciar servidor rsync
echo "[NAS] Iniciando servidor rsync..."
mkdir -p /srv/nas/backups
chmod 777 /srv/nas/backups
cp /services/backups/rsyncd.conf /etc/rsyncd.conf
rsync --daemon

# Dar permisos y configurar cron para backups
chmod +x /srv/nas/backups/backups.sh

echo "[CRON] Configurando tareas en crontab..."
echo "* * * * * root bash /etc/bind/update_zone.sh >> /var/log/dns_update.log 2>&1" >> /etc/crontab
echo "0 2 * * * root /bin/bash /srv/nas/backups/backups.sh >> /var/log/db_backup.log 2>&1" >> /etc/crontab

# Iniciar cron una vez
cron -f &

# Mantener contenedor activo
tail -f /dev/null

# apt update && apt install -y rsync


