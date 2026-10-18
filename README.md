# Practica Azure: matriculas con .NET, Angular y Azure SQL

Una aplicacion de matriculas universitarias (alumnos, docentes, cursos, periodos,
matriculas con aprobacion y constancia en PDF) desplegada en Azure de principio a fin,
paso a paso con Azure CLI, y documentada con cada comando, su salida real y el porque.

No es una plantilla para copiar y pegar: es un laboratorio para entender cada pieza de
un despliegue real, incluidos los errores del camino y como se resolvieron.

## Que demuestra

| Area | Que se hizo |
|---|---|
| **Cloud (Azure)** | Red virtual con NSG de minimo privilegio, VM Ubuntu con identidad administrada, Azure SQL sin servidor cerrada a la subred, Blob Storage privado, Container Registry sin usuario admin |
| **CI/CD** | Azure Pipelines: cada `git push` construye las imagenes, las sube al registro, despliega, espera a que la API este sana, hace rollback si no y lanza una prueba de humo por HTTPS |
| **Seguridad** | HTTPS con Let's Encrypt (TLS 1.3, renovacion automatica), JWT firmado, autorizacion por objeto contra IDOR/BOLA probada con ataques reales, usuario de base de datos con solo `EXECUTE`, contenedores sin root |
| **Observabilidad** | Prometheus + node_exporter + Grafana para la maquina; OpenTelemetry + Collector para la API (metodo RED y percentiles) |
| **Arquitectura** | Comparativa de coste real (precios de Azure) entre este laboratorio y dos arquitecturas de produccion con servicios gestionados |

## Arquitectura

```
                       git push
                          │
             Azure DevOps (repo + pipeline)
                          │  el agente sale a preguntar (HTTPS)
  ── VM Ubuntu con Docker ─────────────────────────────────────────────────────────
   CI/CD     agente ─► docker build ─► push ─► ACR ─► pull ─► compose up ─► healthy?

   Trafico   Internet ─► NSG 80/443 ─► nginx (TLS) ─► API .NET ─► Azure SQL
                                         └─► Angular       └─────► Blob Storage

   Metricas  API ─OTLP─► Collector ─► Prometheus ◄─ node_exporter
             Grafana ◄── tunel SSH ── portatil
  ─────────────────────────────────────────────────────────────────────────────────
```

## Tecnologias

| Capa | Tecnologia |
|---|---|
| Backend | .NET 10 Web API, Dapper, procedimientos almacenados, JWT, QuestPDF |
| Frontend | Angular 22 (componentes standalone, signals), servido por nginx |
| Datos | Azure SQL (sin servidor), Azure Blob Storage |
| Contenedores | Docker, Docker Compose, Azure Container Registry |
| Infraestructura | Azure CLI, VM Ubuntu 24.04, VNet, NSG, identidad administrada, RBAC |
| CI/CD | Azure Pipelines con agente autohospedado |
| Observabilidad | OpenTelemetry, Prometheus, Grafana |
| Seguridad | Let's Encrypt / certbot, nginx con cabeceras de seguridad y HSTS |

## La guia

**[`guia/index.html`](guia/index.html)** es el corazon del proyecto: 23 secciones con
cada paso, su salida real y su explicacion, mas un recorrido completo, conceptos, un
glosario de unos 80 terminos, pendientes y el analisis de coste. Es un HTML
autocontenido: descargalo y abrelo en el navegador.

## Estructura

| Carpeta | Contenido |
|---|---|
| `app/api/` | Web API .NET (`Matriculas.Api`) |
| `app/web/` | Angular, `nginx.conf` y cabeceras de seguridad |
| `app/sql/` | Esquema, datos de ejemplo y procedimientos, numerados por orden de carga |
| `app/observabilidad/` | Prometheus, Grafana y OpenTelemetry Collector |
| `app/desplegar.sh` | Despliegue con espera a healthy, rollback y prueba de humo |
| `azure-pipelines.yml` | El pipeline de CI/CD |
| `guia/` | La documentacion paso a paso |
| `mockup/` | Maquetas HTML de las pantallas |

## Probarlo en local

Requisitos: Docker, Node 22 y el SDK de .NET indicado en `app/api/global.json`.

```bash
cd app
cp .env.ejemplo .env               # y cambiar las contrasenas de ejemplo
docker compose up -d               # SQL Server, Azurite (emulador de Blob) y la API
./cargar-esquema-local.sh          # esquema, datos de ejemplo y procedimientos

cd web
npm ci
npm start                          # http://localhost:4200
```

Cuentas de demostracion (contrasena `admin123.$`):
`ana.quispe@universidad-demo.edu` (alumna) y `gestor@universidad-demo.edu` (gestor).

## Coste

| Escenario | Al mes | Al ano |
|---|---|---|
| Laboratorio, encendido solo para practicar (~60 h/mes) | ~17 USD | ~199 USD |
| Laboratorio encendido 24/7 | ~77 USD | ~929 USD |
| Produccion gestionada pequena (App Service, Static Web Apps, SQL S1, Key Vault) | ~115 USD | ~1 379 USD |
| Produccion con alta disponibilidad y WAF | ~990 USD | ~11 886 USD |

Precios de lista de Azure en `centralus`, sin impuestos. El detalle esta al final de la
guia.

## Notas

- Los nombres de recursos (`demo01`), el dominio, las IPs y la institucion ("Universidad
  Demo") son de ejemplo. Los nombres de ACR, Storage y SQL son globales en Azure: para
  reproducirlo, usa los tuyos.
- No hay secretos en el repositorio: viven en ficheros `.env` ignorados por Git. Los
  `*.ejemplo` son plantillas.
- `LEEME.md` describe el plan inicial (PostgreSQL y Container Apps), que se cambio
  durante la practica; la arquitectura real es la de este README y la guia.
