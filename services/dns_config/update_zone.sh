#!/bin/bash

LEASES="/var/lib/dhcp/dhcpd.leases"
DNS_IP="172.20.0.3"

ZONE_PROD="/etc/bind/db.prod.local"
ZONE_DEV="/etc/bind/db.dev.local"

# Función para generar encabezado de zona
generate_zone_header() {
  local file=$1
  local domain=$2
  cat <<EOF > "$file"
\$TTL    86400
@       IN      SOA     dns.$domain. root.$domain. (
                        $(date +%Y%m%d%H) ; Serial
                        3600       ; Refresh
                        1800       ; Retry
                        1209600    ; Expire
                        86400 )    ; Negative Cache TTL

@       IN      NS      ns.$domain.
ns      IN      A       $DNS_IP

EOF
}

# Generar encabezados
generate_zone_header "$ZONE_PROD" "prod.local"
generate_zone_header "$ZONE_DEV"  "dev.local"

echo "[DNS] Generando registros A desde leases..."
# Extraer registros A desde los leases y clasificar por nombre
awk -v prod_file="$ZONE_PROD" -v dev_file="$ZONE_DEV" '
/lease/ { ip = $2 }
/client-hostname/ {
    hostname = $2
    gsub(/[\";]/, "", hostname)
    if (hostname ~ /prod/) {
        prod[hostname] = ip
    } else if (hostname ~ /dev/) {
        dev[hostname] = ip
    }
}
END {
    for (h in prod) {
        printf "%-20s IN      A       %s\n", h, prod[h] >> prod_file
    }
    for (h in dev) {
        printf "%-20s IN      A       %s\n", h, dev[h] >> dev_file
    }
}
' "$LEASES"
echo "[DNS] Generando registros A desde leases..."
echo "[DNS] Zonas generadas:"
cat "$ZONE_PROD"
cat "$ZONE_DEV"

# Reiniciar BIND
echo "[DNS] Reiniciando BIND con nuevas zonas..."
pkill named
sleep 1
/usr/sbin/named -c /etc/bind/named.conf 







