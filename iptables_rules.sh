#!/bin/sh

# Habilitar reenvío de paquetes en el kernel
echo "1" > /proc/sys/net/ipv4/ip_forward

# Limpiar reglas previas en FORWARD para evitar duplicados
iptables-legacy -F FORWARD
iptables-legacy -X FORWARD

# 🔥 BLOQUEAR TODO EL TRÁFICO POR DEFECTO
iptables-legacy -P FORWARD DROP

# 🔓 PERMITIR tráfico entre services_net (172.20.0.0/24) y production_net (172.30.0.0/24)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -j ACCEPT

# ❌ BLOQUEAR tráfico entre development_net (172.40.0.0/24) y production_net (172.30.0.0/24)
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -j DROP
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -j DROP
