# Laboratorio DevOps en Azure: de la infraestructura a la observabilidad

**Infraestructura paso a paso, CI/CD con Azure Pipelines, HTTPS y observabilidad con
Prometheus, Grafana y OpenTelemetry.** La aplicacion es la excusa: un sistema de
matriculas en .NET y Angular, lo bastante real como para que todo lo demas tenga
sentido.

Cada paso esta documentado con su comando, su salida real y el porque, incluidos los
errores del camino y como se resolvieron. No es una plantilla para copiar y pegar: es
un laboratorio para entender cada pieza de lo que pasa entre un `git push` y un
servicio en produccion que se sabe que funciona.

## El recorrido

| | Que se hizo |
|---|---|
| **1. Infraestructura** | Cada recurso de Azure levantado con Azure CLI: red virtual con NSG de minimo privilegio, VM Ubuntu con identidad administrada, Azure SQL sin servidor cerrada a la subred, Blob Storage privado, Container Registry sin usuario admin |
| **2. Flujo DevOps** | Azure Pipelines: cada `git push` construye las imagenes, las sube al registro, despliega, espera a que la API este sana, hace rollback si no lo esta y lanza una prueba de humo por HTTPS. Un commit que solo toca documentacion no despliega |
| **3. Seguridad** | HTTPS con Let's Encrypt (TLS 1.3, renovacion automatica), JWT firmado, autorizacion por objeto contra IDOR/BOLA probada con ataques reales, usuario de base de datos con solo `EXECUTE`, contenedores sin root, secretos fuera del repositorio |
| **4. Observabilidad** | Ver que pasa dentro sin entrar a la maquina: Prometheus + node_exporter + Grafana para la VM, y OpenTelemetry + Collector para cada peticion a la API (metodo RED: tasa, errores y duracion en percentiles). Fue la observabilidad la que detecto que el disco crecia con cada build |
| **5. Arquitectura** | Coste real con precios de Azure: este laboratorio frente a dos arquitecturas de produccion con servicios gestionados, y el criterio para elegir |

## La aplicacion de ejemplo

Matriculas universitarias: alumnos, docentes, cursos con prerrequisitos, periodos,
solicitudes que aprueba un gestor y constancia en PDF guardada en Blob Storage. API
.NET con todo el acceso a datos por procedimientos almacenados, y Angular con diseno
para escritorio y movil.

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
