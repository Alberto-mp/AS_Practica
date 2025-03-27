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


# Limpia reglas anteriores para evitar duplicados
iptables-legacy -F OUTPUT

# 🔒 DEV_USER → solo puede acceder a 172.40.0.0/24 (development)
iptables-legacy -A OUTPUT -m owner --uid-owner 1000 -d 172.40.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner 1000 -j REJECT

# 🔒 SVC_PROD_USER → solo puede acceder a 172.20.0.0/24 (services) y 172.30.0.0/24 (production)
iptables-legacy -A OUTPUT -m owner --uid-owner 1001 -d 172.20.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner 1001 -d 172.30.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner 1001 -j REJECT
