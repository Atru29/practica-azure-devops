#!/bin/bash
# =====================================================================
#  Deja la base local lista desde cero: esquema, datos, procedimientos
#  y registro de errores.
#
#  Usa el sqlcmd que viene dentro del contenedor, asi que no hace falta
#  instalar nada en el portatil.
#
#  El orden importa: las claves foraneas y los procedimientos no pueden
#  referirse a lo que todavia no existe.
#
#    ./cargar-esquema-local.sh              carga sobre lo que haya
#    ./cargar-esquema-local.sh --reiniciar  borra appdb y empieza de cero
#
#  Sin --reiniciar, si las tablas ya existen, 01-esquema.sql falla y los
#  datos NO se recargan. Eso es lo que quieres cuando solo cambias un
#  procedimiento, y lo que NO quieres cuando cambias los datos de ejemplo.
# =====================================================================
set -e

cd "$(dirname "$0")"
[ -f .env ] || { echo "Falta .env. Copialo de .env.ejemplo"; exit 1; }

# Se lee SOLO esta variable, sin 'source': la cadena de conexion lleva
# ";" y el shell los tomaria como separadores de comandos.
CLAVE=$(grep -E '^SQL_PASSWORD=' .env | head -1 | cut -d= -f2- | tr -d '"')
[ -n "$CLAVE" ] || { echo "No encuentro SQL_PASSWORD en .env"; exit 1; }

# -I activa QUOTED_IDENTIFIER, que sqlcmd trae apagado y que exigen
# las columnas calculadas PERSISTED de ErrorLog.
sql() {
  docker exec -i matriculas-sql /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "$CLAVE" -C -I -l 60 "$@"
}

echo "=== esperando a que SQL Server responda ==="
for i in $(seq 1 30); do
  if sql -Q "SELECT 1" >/dev/null 2>&1; then echo " listo"; break; fi
  printf '.'
  sleep 3
done

if [ "$1" = "--reiniciar" ]; then
  echo "=== borrando appdb ==="
  # SINGLE_USER con ROLLBACK IMMEDIATE echa a cualquiera que este
  # conectado; si no, el DROP se queda esperando para siempre.
  sql -Q "IF DB_ID('appdb') IS NOT NULL
          BEGIN
              ALTER DATABASE appdb SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
              DROP DATABASE appdb;
          END"
fi

echo "=== creando la base appdb ==="
sql -i /dev/stdin < sql/00-local-crear-base.sql

for fichero in sql/01-esquema.sql \
               sql/02-datos-ejemplo.sql \
               sql/06-errorlog.sql \
               sql/04-procedimientos.sql; do
  echo "=== $fichero ==="
  sql -d appdb -i /dev/stdin < "$fichero"
done

# 05-usuario-aplicacion.sql se deja aparte a proposito: en local se
# trabaja con 'sa' y crear el usuario restringido solo estorbaria.
# En Azure si hay que cargarlo.

echo
echo "=== resultado ==="
sql -d appdb -W -s'|' -Q "
SELECT Tablas         = (SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE='BASE TABLE'),
       Procedimientos = (SELECT COUNT(*) FROM sys.procedures),
       Alumnos        = (SELECT COUNT(*) FROM dbo.Alumno),
       Cursos         = (SELECT COUNT(*) FROM dbo.Curso)"
