# 📌 Pruebas de Funcionamiento - Router y DHCP en Docker

## ✅ 1. Verificar que los contenedores están corriendo
Ejecuta el siguiente comando para comprobar que `router` y `dhcp_client` están en ejecución:

```sh
docker ps
```
Si dhcp_client no aparece en la lista, ejecuta:
```sh
docker-compose up -d --build
```

## ✅ 2. Verificar que el cliente DHCP ha recibido una IP
Ejecuta el siguiente comando para ver las interfaces de red en el cliente DHCP:
```sh
docker exec -it dhcp_client ip a
```
### 📌 Salida esperada:
Debe mostrar una IP en eth0 dentro del rango 172.20.0.10 - 172.20.0.100, como:
``bash
inet 172.20.0.3/24 brd 172.20.0.255 scope global eth0
```
Si el cliente no tiene IP, intenta solicitar una nueva IP manualmente con:
```sh
docker exec -it dhcp_client dhclient eth0
```
## ✅ 3. Probar conectividad con el router
Ejecuta un ping al router desde el cliente DHCP:
```sh
docker exec -it dhcp_client ping -c 4 172.20.0.2
```
### 📌 Salida esperada:
```bash
64 bytes from 172.20.0.2: icmp_seq=1 ttl=64 time=0.123 ms
```
## 4. Probar conectividad entre redes
Si hay otro contenedor en production_net, prueba la conexión desde el cliente en services_net:
```sh
docker exec -it dhcp_client ping -c 4 172.30.0.10
```
