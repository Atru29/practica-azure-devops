#!/bin/sh
# =====================================================================
#  Deploy hook de certbot: se ejecuta cada vez que obtiene o renueva el
#  certificado (no en los intentos que no cambian nada).
#
#  En la maquina va en:
#      /etc/letsencrypt/renewal-hooks/deploy/matriculas.sh
#
#  Por que hace falta: certbot deja la clave privada legible solo por
#  root, y nginx corre en su contenedor como el usuario nginx (uid 101).
#  Montar /etc/letsencrypt tal cual daria "Permission denied" y nginx no
#  arrancaria. Se copia a un directorio propio con dueno 101 y nada mas.
# =====================================================================
set -e

DOMINIO=demo01-prod.centralus.cloudapp.azure.com
ORIGEN=/etc/letsencrypt/live/$DOMINIO
DESTINO=/etc/matriculas-tls

# install copia el CONTENIDO (live/ son enlaces a archive/) y fija dueno
# y permisos en el mismo paso: no hay un instante en que la clave quede
# con permisos abiertos.
install -d -o 101 -g 101 -m 700 "$DESTINO"
install -o 101 -g 101 -m 600 "$ORIGEN/fullchain.pem" "$DESTINO/fullchain.pem"
install -o 101 -g 101 -m 600 "$ORIGEN/privkey.pem"   "$DESTINO/privkey.pem"

# nginx lee el certificado al arrancar: recargar para que use el nuevo
# sin cortar conexiones. Si el contenedor no esta corriendo (la primera
# emision), no pasa nada: lo leera al arrancar.
docker exec matriculas-web nginx -s reload 2>/dev/null || true
