#!/bin/sh

# Habilitar reenvío de paquetes en el kernel
echo "1" > /proc/sys/net/ipv4/ip_forward

iptables-legacy -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-legacy -t nat -A POSTROUTING -o eth1 -j MASQUERADE
iptables-legacy -t nat -A POSTROUTING -o eth2 -j MASQUERADE
iptables-legacy -t nat -A POSTROUTING -o eth3 -j MASQUERADE


# Limpiar reglas previas en FORWARD para evitar duplicados
iptables-legacy -F FORWARD
iptables-legacy -X FORWARD

# 🔥 BLOQUEAR TODO EL TRÁFICO POR DEFECTO
iptables-legacy -P FORWARD DROP

# 🔒 BLOQUEAR tráfico entre production_net (172.30.0.0/24) y development_net (172.40.0.0/24)
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -j DROP
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -j DROP

# 🔓 PERMITIR tráfico entre services_net (172.20.0.0/24) y production_net (172.30.0.0/24)

# Permitir tráfico de rsync (puerto 873) entre Production y Services
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -p tcp --dport 873 -j ACCEPT
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -p tcp --dport 873 -j ACCEPT

# 🔓 PERMITIR comunicación libre entre services_net (172.20.0.0/24) y development_net (172.40.0.0/24)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.40.0.0/24 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.20.0.0/24 -j ACCEPT

# Obtener UID de los usuarios
DEV_UID=$(id -u devuser)
PROD_UID=$(id -u produser)

# 🚫 Bloquear todo el tráfico de devuser que no sea a Development (172.40.0.0/24)
iptables-legacy -A OUTPUT -m owner --uid-owner $DEV_UID ! -d 172.40.0.0/24 -j REJECT

# ✅ Permitir primero el tráfico válido
iptables-legacy -A OUTPUT -m owner --uid-owner $PROD_UID -d 172.20.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner $PROD_UID -d 172.30.0.0/24 -j ACCEPT
# ❌ Y luego rechazar todo lo demás
iptables-legacy -A OUTPUT -m owner --uid-owner $PROD_UID -j REJECT
