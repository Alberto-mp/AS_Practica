#!/bin/sh

# 🔧 Habilitar reenvío de paquetes en el kernel
echo "1" > /proc/sys/net/ipv4/ip_forward

# 🧹 Limpiar reglas previas para evitar duplicados
iptables-legacy -F FORWARD
iptables-legacy -F OUTPUT
iptables-legacy -t nat -F

# 🔐 Bloquear todo el tráfico por defecto
iptables-legacy -P FORWARD DROP
iptables-legacy -P OUTPUT DROP

# ✅ Permitir al router usar DNS del NAS
iptables-legacy -A OUTPUT -d 172.20.0.3 -p udp --dport 53 -j ACCEPT
iptables-legacy -A OUTPUT -d 172.20.0.3 -p tcp --dport 53 -j ACCEPT

# ✅ Permitir ping (ICMP) desde el router
iptables-legacy -A OUTPUT -p icmp -j ACCEPT

# ✅ Permitir resolver dominios externos vía DNS externo (opcional, si usas DNS público)
iptables-legacy -A OUTPUT -p udp --dport 53 -j ACCEPT

# 🔄 Hacer NAT solo para las redes internas que salen por eth0
iptables-legacy -t nat -A POSTROUTING -s 172.20.0.0/24 -o eth0 -j MASQUERADE
iptables-legacy -t nat -A POSTROUTING -s 172.30.0.0/24 -o eth0 -j MASQUERADE
iptables-legacy -t nat -A POSTROUTING -s 172.40.0.0/24 -o eth0 -j MASQUERADE

# ✅ Permitir tráfico desde redes internas hacia afuera (Internet)
iptables-legacy -A FORWARD -s 172.20.0.0/24 -o eth0 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -o eth0 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -o eth0 -j ACCEPT

# ✅ Permitir tráfico de retorno desde Internet hacia redes internas
iptables-legacy -A FORWARD -d 172.20.0.0/24 -i eth0 -j ACCEPT
iptables-legacy -A FORWARD -d 172.30.0.0/24 -i eth0 -j ACCEPT
iptables-legacy -A FORWARD -d 172.40.0.0/24 -i eth0 -j ACCEPT

# 🔒 Bloquear tráfico entre production_net y development_net
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -j DROP
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -j DROP

# ❌ Bloquear específicamente ICMP (ping) entre Production y Development
iptables-legacy -I FORWARD -s 172.30.0.0/24 -d 172.40.0.0/24 -p icmp -j DROP
iptables-legacy -I FORWARD -s 172.40.0.0/24 -d 172.30.0.0/24 -p icmp -j DROP

# ✅ Permitir solo PostgreSQL y rsync entre Production y Services
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -p tcp --dport 5432 -j ACCEPT
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -p tcp --dport 5432 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.0/24 -p tcp --dport 873 -j ACCEPT
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.30.0.0/24 -p tcp --dport 873 -j ACCEPT

# 🔓 Permitir tráfico libre entre Services y Development
iptables-legacy -A FORWARD -s 172.20.0.0/24 -d 172.40.0.0/24 -j ACCEPT
iptables-legacy -A FORWARD -s 172.40.0.0/24 -d 172.20.0.0/24 -j ACCEPT


# 🚫 Control de salida por usuario

# Obtener UID de los usuarios si existen
DEV_UID=$(id -u devuser 2>/dev/null || echo 99999)
PROD_UID=$(id -u produser 2>/dev/null || echo 99998)

# 🚫 Bloquear tráfico del devuser que no sea a su red
iptables-legacy -A OUTPUT -m owner --uid-owner $DEV_UID ! -d 172.40.0.0/24 -j REJECT

# ✅ Permitir tráfico del produser a services y production
iptables-legacy -A OUTPUT -m owner --uid-owner $PROD_UID -d 172.20.0.0/24 -j ACCEPT
iptables-legacy -A OUTPUT -m owner --uid-owner $PROD_UID -d 172.30.0.0/24 -j ACCEPT

# ✅ Permitir tráfico DNS para todos (necesario para apt update)
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.3 -p udp --dport 53 -j ACCEPT
iptables-legacy -A FORWARD -s 172.30.0.0/24 -d 172.20.0.3 -p tcp --dport 53 -j ACCEPT

# ✅ Permitir tráfico HTTP/HTTPS para todos (necesario para apt update)
iptables-legacy -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables-legacy -A OUTPUT -p tcp --dport 443 -j ACCEPT

# ❌ Rechazar todo lo demás del produser
iptables-legacy -A OUTPUT -m owner --uid-owner $PROD_UID -j REJECT

# 🔄 Permitir respuestas a conexiones establecidas desde Internet
iptables-legacy -A FORWARD -m state --state ESTABLISHED,RELATED -j ACCEPT
