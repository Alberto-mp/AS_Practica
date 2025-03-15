#!/bin/bash

# Función para probar un ping y mostrar el resultado
test_ping() {
    local net=$1
    local ip=$2
    local expected=$3

    echo -n "[$net] Pinging $ip ... "
    docker run --rm --net=$net busybox ping -c 2 $ip &> /dev/null

    if [ $? -eq 0 ]; then
        if [ "$expected" == "allow" ]; then
            echo "✅ SUCCESS (Allowed)"
        else
            echo "❌ ERROR (Should be BLOCKED!)"
        fi
    else
        if [ "$expected" == "deny" ]; then
            echo "✅ SUCCESS (Blocked)"
        else
            echo "❌ ERROR (Should be ALLOWED!)"
        fi
    fi
}

echo "========================="
echo "✅ TESTING ALLOWED PINGS"
echo "========================="
test_ping development_net 172.40.0.2 allow   # Router en development_net
test_ping development_net 172.40.0.3 allow   # Otro contenedor en development_net
test_ping services_net 172.20.0.2 allow      # Router en services_net
test_ping services_net 172.30.0.3 allow      # Comunicación services_net -> production_net
test_ping production_net 172.30.0.2 allow    # Router en production_net
test_ping production_net 172.20.0.3 allow    # PostgreSQL permitido services_net <-> production_net

echo ""
echo "========================="
echo "❌ TESTING BLOCKED PINGS"
echo "========================="
test_ping development_net 172.20.0.3 deny    # No acceso a services_net
test_ping development_net 172.30.0.3 deny    # No acceso a production_net
test_ping services_net 172.40.0.3 deny       # No acceso a development_net
test_ping production_net 172.40.0.3 deny     # No acceso a development_net
test_ping production_net 172.30.0.3 deny     # No acceso a otro host en production_net (según reglas)
test_ping production_net 172.40.0.2 deny     # No acceso al router desde production_net

echo ""
echo "========================="
echo "✅ PING TESTING COMPLETED"
echo "========================="
