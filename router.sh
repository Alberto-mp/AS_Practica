#!/bin/sh

# Habilitar el reenvío de paquetes
echo 1 > /proc/sys/net/ipv4/ip_forward

# Política predeterminada: permitir tráfico
iptables -P FORWARD ACCEPT

# Permitir tráfico entre production_net y development_net
iptables -A FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -j ACCEPT
iptables -A FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -j ACCEPT

# Permitir tráfico entre production_net y service_net
iptables -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -j ACCEPT
iptables -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -j ACCEPT

# Permitir tráfico entre development_net y service_net
iptables -A FORWARD -s 172.40.0.0/24 -d 172.20.0.0/24 -j ACCEPT
iptables -A FORWARD -s 172.20.0.0/24 -d 172.40.0.0/24 -j ACCEPT
