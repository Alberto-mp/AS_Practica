#!/bin/sh

# Habilitar reenvío de paquetes en el kernel
echo "1" > /proc/sys/net/ipv4/ip_forward

# NAT saliente por todas las interfaces reales
for iface in eth0 eth1 eth2 eth3; do
  iptables-legacy -t nat -A POSTROUTING -o $iface -j MASQUERADE
done

# Limpiar reglas previas
iptables-legacy -F FORWARD
iptables-legacy -X FORWARD
iptables-legacy -F OUTPUT

# Política por defecto
iptables-legacy -P FORWARD DROP

# Bloquear tráfico entre production y development
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -j DROP
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -j DROP
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -j DROP

# Permitir tráfico rsync entre production y services
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -p tcp --dport 873 -j ACCEPT
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -p tcp --dport 873 -j ACCEPT

# Permitir comunicación entre services y development
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.40.0.0/24 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.20.0.0/24 -j ACCEPT

# Reglas por usuario (output)
iptables-legacy -A OUTPUT -m owner --uid-owner 1000 -d 172.40.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner 1000 -j REJECT

iptables-legacy -A OUTPUT -m owner --uid-owner 1001 -d 172.20.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner 1001 -d 172.30.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner 1001 -j REJECT

# Permitir salida a Internet (suponiendo que eth3 es el gateway externo)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -o eth0 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -o eth0 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -o eth0 -j ACCEPT

# Permitir salida a Internet (suponiendo que eth3 es el gateway externo)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -o eth1 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -o eth1 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -o eth1 -j ACCEPT

# Permitir salida a Internet (suponiendo que eth3 es el gateway externo)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -o eth2 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -o eth2 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -o eth2 -j ACCEPT

# Permitir salida a Internet (suponiendo que eth3 es el gateway externo)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -o eth3 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -o eth3 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -o eth3 -j ACCEPT

# Permitir paquetes de retorno
iptables-legacy -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
