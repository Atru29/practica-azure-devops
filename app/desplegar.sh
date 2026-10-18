#!/bin/bash
# =====================================================================
#  Despliega una version ya subida al registro. Se ejecuta EN LA MAQUINA,
#  en ~/matriculas, donde estan docker-compose.prod.yml y .env.prod.
#
#      ./desplegar.sh <etiqueta>          p. ej. ./desplegar.sh a0e24b0
#
#  Lo usa el pipeline (etapa Desplegar) y sirve igual a mano: es el
#  bloque de comandos del paso 18 de la guia, con dos anadidos que a
#  mano se olvidan:
#    - espera a que la API este 'healthy' antes de dar nada por bueno
#    - si no llega a estarlo, vuelve a la version anterior (rollback)
# =====================================================================
set -euo pipefail

ETIQUETA="${1:?Uso: desplegar.sh <etiqueta>}"
DIRECTORIO="${DIRECTORIO:-$HOME/matriculas}"
REGISTRO_NOMBRE=acrdemo01prod
DOMINIO=demo01-prod.centralus.cloudapp.azure.com

cd "$DIRECTORIO"
compose() { docker compose --file docker-compose.prod.yml --env-file .env.prod "$@"; }

ANTERIOR=$(grep '^ETIQUETA=' .env.prod | cut -d= -f2)
echo "=== desplegando $ETIQUETA (ahora corre $ANTERIOR) ==="

# El token del registro dura 3 horas: se pide uno nuevo en cada despliegue.
az acr login --name "$REGISTRO_NOMBRE"

sed -i "s/^ETIQUETA=.*/ETIQUETA=$ETIQUETA/" .env.prod
compose pull
compose up --detach

# --- esperar a que la API diga que esta sana (hasta 2 minutos) ---
estado=""
for intento in $(seq 1 24); do
    estado=$(docker inspect --format '{{.State.Health.Status}}' matriculas-api)
    echo "  intento $intento: api $estado"
    [ "$estado" = "healthy" ] && break
    sleep 5
done

if [ "$estado" != "healthy" ]; then
    echo "=== la API no llego a healthy: ultimas lineas del registro ==="
    docker logs --tail 40 matriculas-api || true
    echo "=== ROLLBACK a $ANTERIOR ==="
    sed -i "s/^ETIQUETA=.*/ETIQUETA=$ANTERIOR/" .env.prod
    compose up --detach
    exit 1
fi

# --- prueba de humo: la cadena completa nginx -> TLS -> API ---
# --resolve conecta a esta misma maquina pero valida el certificado
# contra el nombre real, igual que lo haria un navegador.
curl --fail --silent --show-error \
     --resolve "$DOMINIO:443:127.0.0.1" "https://$DOMINIO/salud"
echo
echo "=== $ETIQUETA desplegada ==="

# Imagenes sin etiqueta que quedan de builds anteriores: no las usa nadie
# y van llenando el disco.
docker image prune --force
