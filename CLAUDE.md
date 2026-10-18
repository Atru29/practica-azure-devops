# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Que es este repositorio

Practica de despliegue en Azure de una aplicacion de matriculas (alumnos, docentes, cursos, periodos, matriculas con aprobacion y constancia en PDF). Todo el codigo, comentarios, nombres de identificadores y mensajes de commit estan en **espanol sin tildes**; mantener esa convencion.

- `app/api/` — Web API en .NET 10 (`Matriculas.Api`), Dapper + SQL Server, JWT, QuestPDF, Azure Blob Storage.
- `app/web/` — Angular 22 (componentes standalone, signals, rutas con `loadComponent`).
- `app/sql/` — esquema, datos de ejemplo y procedimientos almacenados, numerados por orden de carga.
- `guia/index.html` — la documentacion de la practica: cada paso de Azure CLI con su salida real y el porque. Es la fuente de verdad de la infraestructura.
- `mockup/` — maquetas HTML estaticas de las pantallas.
- `_bicep-para-mas-adelante/` — borrador Bicep aparcado; no se usa.

**Ojo:** `LEEME.md` esta desactualizado (habla de PostgreSQL, Container Apps y Static Web Apps). La topologia real, segun la guia y los compose, es: una maquina virtual con Docker que corre nginx (frontend) + API, base de datos Azure SQL (capa gratuita sin servidor) y una cuenta de Storage para las constancias. La region acabo siendo `centralus`.

## Comandos

Todos desde `app/` salvo que se indique. Node 22 (`.nvmrc`), SDK .NET fijado en `app/api/global.json`.

```bash
# Entorno local (SQL Server en 1435, Azurite en 10000, API en 5080)
cp .env.ejemplo .env
docker compose up -d                      # sqlserver + almacen + api
./cargar-esquema-local.sh                 # carga 00,01,02,06,04 (en ese orden)
./cargar-esquema-local.sh --reiniciar     # borra appdb y recarga todo
docker compose up -d --build api          # reconstruir la API tras cambiar C#

# API fuera de Docker (puerto 5031 segun launchSettings; el proxy de Angular apunta a 5080)
cd api/Matriculas.Api
dotnet user-secrets set "ConnectionStrings:Matriculas" "..."
dotnet user-secrets set "Jwt:Clave" "..."   # tambien Almacen:Conexion / Almacen:Contenedor
dotnet build
dotnet run
# Matriculas.Api.http tiene peticiones de ejemplo

# Frontend
cd web
npm ci
npm start          # ng serve en :4200, proxy.conf.json reenvia /api y /salud a localhost:5080
npm run build
npm test           # vitest via ng test (no hay specs escritos todavia)

# Produccion: lo normal es el pipeline (azure-pipelines.yml): cada push a main
# que toque app/api, app/web, el compose o app/desplegar.sh construye, sube y
# despliega solo. Agente autohospedado en la propia maquina (pool Default).
# A mano, el equivalente es construir en el portatil y subir a acrdemo01prod,
# etiquetando con el hash del commit (git rev-parse --short HEAD)
az acr login --name acrdemo01prod
docker build --tag acrdemo01prod.azurecr.io/matriculas-api:<hash> api
docker push acrdemo01prod.azurecr.io/matriculas-api:<hash>      # igual con matriculas-web y web/

# En la maquina, en ~/matriculas (ETIQUETA=<hash> en .env.prod). Sin --env-file
# compose no lee .env.prod y falla con "falta SQL_CONEXION"
az login --identity && az acr login --name acrdemo01prod      # el token dura 3 h
bash desplegar.sh <hash>  # app/desplegar.sh copiado a la maquina (el pipeline lo usa desde su checkout):
                          # pull + up + espera healthy (rollback si no) + prueba https
```

No hay proyecto de pruebas .NET ni linter configurado (solo `.prettierrc` en `web/`).

## Arquitectura

### Todo el acceso a datos pasa por procedimientos almacenados

La API no contiene SQL. La cadena es: `Controller` → `Servicio` → `Repositorio` → `DbFactoryBase` → `usp_*`.

- `Comun/DbFactoryBase.cs` es la unica clase que conoce Dapper; siempre usa `CommandType.StoredProcedure`. Los repositorios heredan de ella.
- `Comun/Procedimientos.cs` centraliza los nombres de los procedimientos como constantes. Un procedimiento nuevo se anade alli y en `sql/04-procedimientos.sql`.
- Los parametros siguen el prefijo de tipo de la base: `@i_` entero, `@v_` texto, `@d_` fecha, `@b_` bit. Los objetos anonimos de Dapper usan esos mismos nombres (`new { i_alumnoId = ..., v_cursos = ... }`).
- Las listas de cursos viajan como CSV (`'1,3,7'`); la conversion se hace en el servicio (`AListaCsv`), no en el controlador.
- Los procedimientos de varios conjuntos de resultados (p. ej. `usp_Matricula_Obtener`: cabecera + cursos) se leen con `ConsultarMultipleAsync` en el orden exacto en que los devuelve el SQL.

Las reglas de integridad y de estado viven en los procedimientos; el servicio .NET solo pone las reglas que dependen de **quien** pide (p. ej. un alumno solo ve sus matriculas → 404 vs 403).

### Contrato de errores SQL → HTTP

Los procedimientos lanzan `THROW` con codigos propios, y `Comun/ManejadorDeErrores.cs` + `Comun/ErroresSql.cs` los traducen a ProblemDetails:

| Codigo | HTTP |
|---|---|
| 50001–50009 datos invalidos | 400 |
| 50010–50019 estado incorrecto | 409 |
| 50020–50029 no encontrado | 404 |

Solo los mensajes de errores >= 50000 se devuelven al cliente; el resto se ocultan y se registran. Los procedimientos que escriben siguen la plantilla documentada en la cabecera de `04-procedimientos.sql` (validar fuera de la transaccion, `XACT_ABORT`, `CATCH` → rollback → registrar en `ErrorLog` → `THROW`). `06-errorlog.sql` debe cargarse antes que `04`.

### Identidad y roles

Roles: `Alumno`, `Docente`, `Gestor`. El JWT lleva el rol y, para alumnos, su `AlumnoId`; los controladores sacan los ids **del token**, nunca del cuerpo. `ClockSkew = 0`. En Angular, `nucleo/guardas` solo oculta pantallas; la autorizacion real es `[Authorize(Roles = ...)]` en la API, y las rutas del frontend deben coincidir con lo que la API permite a cada rol.

### Un solo origen

Angular llama siempre a rutas relativas `/api/...`. En desarrollo las reenvia `proxy.conf.json`; en produccion `web/nginx.conf` hace `proxy_pass` a `http://api:8080`. La API no publica puerto en produccion. CORS solo se activa en Development. Las cabeceras de seguridad (incluido HSTS) estan en `web/seguridad.inc` y se incluyen en cada `location` que tenga sus propios `add_header` (nginx no los acumula).

### HTTPS

El nginx del contenedor `web` termina el TLS: escucha en 8080 (solo redirige a https, salvo `/.well-known/acme-challenge/`) y 8443 (TLS), publicados como 80 y 443. El certificado es de Let's Encrypt y lo gestiona **certbot en la maquina** (modo webroot sobre `/var/www/certbot`). `app/certbot-deploy-hook.sh` va en `/etc/letsencrypt/renewal-hooks/deploy/` y copia el certificado a `/etc/matriculas-tls` con dueno uid 101 (el usuario `nginx` del contenedor; la clave original solo la lee root). Sin esos ficheros el contenedor `web` no arranca, y la imagen `web` no sirve para local (en local se usa `ng serve`).

### Constancias

`Modulos/Constancias`: QuestPDF genera el PDF, `AlmacenDeArchivos` (singleton) lo sube a Blob Storage y la ruta se guarda con `usp_Matricula_GuardarConstancia`. En local se usa Azurite (cadena con credenciales publicas del emulador en `docker-compose.yml`). La imagen de la API instala `libfontconfig1` y `fonts-dejavu-core` porque QuestPDF/SkiaSharp las necesita.

### Frontend

- `nucleo/` — servicios compartidos (`Api` con metodos que devuelven promesas via `firstValueFrom`, `Autenticacion` basada en signals con la sesion en `localStorage`), interceptor que anade el Bearer, guardas, modelos.
- `paginas/` — una carpeta por pantalla, agrupadas por rol (`alumno/`, `gestor/`).
- `Aviso` es para mensajes de accion que se borran a los 3 s; los errores de carga deben quedarse visibles.

### Base de datos: local vs Azure

- Local: SQL Server 2022 Developer en contenedor, usuario `sa`; `05-usuario-aplicacion.sql` no se carga.
- Recargar tras un cambio: sin `--reiniciar`, `01-esquema.sql` falla porque las tablas ya existen y los datos de ejemplo no se recargan, pero `04` usa `CREATE OR ALTER` y se aplica igual. Para cambiar un procedimiento basta con eso; para cambiar esquema o datos de ejemplo hace falta `--reiniciar`.
- Al ejecutar los `.sql` con `sqlcmd` a mano (tambien contra Azure) hay que pasar `-I` (QUOTED_IDENTIFIER): lo exigen las columnas calculadas `PERSISTED` de `ErrorLog`.
- Azure: la API conecta con `app_matriculas`, que solo tiene `EXECUTE` sobre `dbo`. Se crea con `sqlcmd -v CLAVE_APP="..." -i 05-usuario-aplicacion.sql`. `00-azure-limpiar.sql` vacia la base sin `DROP DATABASE` (para no perder la configuracion de capa gratuita).
- `/salud` no toca la base a proposito: mantendria despierta la base sin servidor y consumiria las horas gratuitas.

Secretos: nunca en `appsettings*.json`. Local → `.env` o `dotnet user-secrets`; produccion → `.env.prod` en la maquina (plantilla en `.env.prod.ejemplo`). Los ficheros `*.ejemplo` si se versionan.
