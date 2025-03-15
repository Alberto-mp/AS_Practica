FROM debian:latest

# Instalar paquetes necesarios
RUN apt-get update && apt-get install -y isc-dhcp-server iproute2 iptables

# Crear directorios necesarios
RUN mkdir -p /var/lib/dhcp

# Copiar el archivo de configuración del DHCP
COPY dhcpd.conf /etc/dhcp/dhcpd.conf

# Configurar el comando de arranque desde docker-compose
CMD ["sleep", "infinity"]
