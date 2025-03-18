#!/bin/sh

# Habilitar reenvío de paquetes en el kernel
echo "1" > /proc/sys/net/ipv4/ip_forward

# Limpiar reglas previas en FORWARD para evitar duplicados
iptables-legacy -F FORWARD
iptables-legacy -X FORWARD

# 🔥 BLOQUEAR TODO EL TRÁFICO POR DEFECTO
iptables-legacy -P FORWARD DROP

# 🔒 BLOQUEAR tráfico entre production_net (172.30.0.0/24) y development_net (172.40.0.0/24)
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -j DROP
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -j DROP

# 🔓 PERMITIR tráfico entre services_net (172.20.0.0/24) y production_net (172.30.0.0/24)
# Pero solo para PostgreSQL (puerto 5432) y rsync (puerto 873)

# Permitir tráfico de PostgreSQL desde Production hacia Services
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -p tcp --dport 5432 -j ACCEPT

# Permitir tráfico de PostgreSQL desde Services hacia Production (en caso de que sea necesario)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -p tcp --dport 5432 -j ACCEPT

# Permitir tráfico de rsync (puerto 873) entre Production y Services
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -p tcp --dport 873 -j ACCEPT
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -p tcp --dport 873 -j ACCEPT
