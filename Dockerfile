FROM debian:latest

# Instalar paquetes necesarios
RUN apt-get update && apt-get install -y isc-dhcp-server iproute2 

# Instalar iptables y herramientas necesarias
RUN apt-get update && apt-get install -y iptables && \
    update-alternatives --set iptables /usr/sbin/iptables-legacy && \
    update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

# Crear directorios necesarios
RUN mkdir -p /var/lib/dhcp

# Copiar el archivo de configuración del DHCP
COPY dhcpd.conf /etc/dhcp/dhcpd.conf



# Configurar el comando de arranque desde docker-compose
CMD ["sleep", "infinity"]
