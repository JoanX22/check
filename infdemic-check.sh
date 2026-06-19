#!/usr/bin/env bash

set -u

ERRORES=0

mostrar_ok() {
printf '[OK] %s\n' "$1"
}

mostrar_error() {
printf '[ERROR] %s\n' "$1"
ERRORES=$((ERRORES + 1))
}

comprobar_servicio() {
local SERVICIO="$1"

```
if systemctl is-active --quiet "${SERVICIO}"; then
    mostrar_ok "${SERVICIO}"
else
    mostrar_error "${SERVICIO}"
fi
```

}

echo "========================================"
echo " COMPROBACIÓN FINAL DE INFDEMIC"
echo "========================================"

echo
echo "SERVICIOS"

comprobar_servicio mysql.service
comprobar_servicio nginx.service
comprobar_servicio infdemic-backend.service
comprobar_servicio fail2ban.service
comprobar_servicio [openvpn-server@server.service](mailto:openvpn-server@server.service)
comprobar_servicio infdemic-backup.timer

echo
echo "API Y FRONTEND"

if curl -fsS 
--max-time 5 
http://127.0.0.1/api/health 
> /dev/null
then
mostrar_ok "API mediante Nginx"
else
mostrar_error "API mediante Nginx"
fi

if curl -fsS 
--max-time 5 
http://127.0.0.1/login.html 
> /dev/null
then
mostrar_ok "Frontend mediante Nginx"
else
mostrar_error "Frontend mediante Nginx"
fi

echo
echo "INTERFAZ VPN"

if ip -4 -o address show dev tun0 2>/dev/null 
| awk '{print $4}' 
| grep -qx '10.100.0.1/24'
then
mostrar_ok "tun0 con 10.100.0.1/24"
else
mostrar_error "tun0 con 10.100.0.1/24"
fi

echo
echo "CORTAFUEGOS"

if ufw status 
| grep -q '^Status: active'
then
mostrar_ok "UFW activo"
else
mostrar_error "UFW activo"
fi

echo
echo "FAIL2BAN"

if fail2ban-client status sshd 
> /dev/null 2>&1
then
mostrar_ok "Jail sshd activo"
else
mostrar_error "Jail sshd activo"
fi

echo
echo "BACKEND"

if ss -lntH 
| awk '{print $4}' 
| grep -qx '127.0.0.1:3000'
then
mostrar_ok "Backend en 127.0.0.1:3000"
else
mostrar_error "Backend en 127.0.0.1:3000"
fi

if ss -lntH 
| awk '{print $4}' 
| grep -Eq '^(0.0.0.0|[::]|*):3000$'
then
mostrar_error "El puerto 3000 está expuesto"
else
mostrar_ok "El puerto 3000 no está expuesto"
fi

echo
echo "MYSQL"

if ss -lntH 
| awk '{print $4}' 
| grep -Eq '^(127.0.0.1|[::1]):3306$'
then
mostrar_ok "MySQL limitado a localhost:3306"
else
mostrar_error "MySQL limitado a localhost:3306"
fi

if ss -lntH 
| awk '{print $4}' 
| grep -Eq '^(0.0.0.0|[::]|*):3306$'
then
mostrar_error "El puerto 3306 está expuesto"
else
mostrar_ok "El puerto 3306 no está expuesto"
fi

echo
echo "COPIAS DE SEGURIDAD"

if find 
/var/backups/infdemic 
-maxdepth 1 
-type f 
-name 'infdemic_*.tar.gz' 
-print 
-quit 
| grep -q .
then
mostrar_ok "Existe al menos una copia"
else
mostrar_error "No existe ninguna copia"
fi

echo
echo "TEMPORIZADOR"

if systemctl is-enabled --quiet infdemic-backup.timer
then
mostrar_ok "Temporizador habilitado"
else
mostrar_error "Temporizador no habilitado"
fi

echo
echo "========================================"

if [[ "${ERRORES}" -eq 0 ]]; then
echo "INFDEMIC funciona correctamente."
exit 0
fi

echo "Se encontraron ${ERRORES} errores."
exit 1
