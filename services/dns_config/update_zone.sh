#!/bin/bash

LEASES="/var/lib/dhcp/dhcpd.leases"
ZONE_FILE="/etc/bind/db.local.zone"

# IP del servidor DNS (ajústala si cambia)
DNS_IP="172.20.0.3"

# Encabezado de la zona
cat <<EOF > "$ZONE_FILE"
\$TTL    86400
@       IN      SOA     dns.local. root.local. (
                        $(date +%Y%m%d%H) ; Serial
                        3600       ; Refresh
                        1800       ; Retry
                        1209600    ; Expire
                        86400 )    ; Negative Cache TTL

@               IN      NS      ns.prod.local.
ns              IN      A       $DNS_IP

EOF

# Extraer registros A desde el archivo de leases
awk '
/lease/ { ip = $2 }
/client-hostname/ {
    gsub(/[\";]/, "", $2)
    hostname = $2
    if (!(hostname in hosts)) {
        hosts[hostname] = ip
    }
}
END {
    for (h in hosts) {
        printf "%-15s IN      A       %s\n", h, hosts[h]
    }
}
' "$LEASES" >> "$ZONE_FILE"


# Reiniciar BIND manualmente
echo "[DNS] Reiniciando BIND manualmente..."
pkill named
sleep 1
/usr/sbin/named -c /etc/bind/named.conf -g &






