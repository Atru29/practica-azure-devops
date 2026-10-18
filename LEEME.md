# PracticaLaboratorios

Topologia de aplicacion web en Azure, montada paso a paso con Azure CLI:

- **Frontend** Angular en Static Web Apps
- **Backend** .NET en contenedor sobre Container Apps
- **Base de datos** PostgreSQL Flexible Server con acceso privado
- **Secretos** en Key Vault

Region `eastus`, entorno `dev`.

## Que hay aqui

| Carpeta | Contenido |
|---|---|
| `guia/index.html` | La documentacion: cada paso con su comando, su salida real y por que se hace asi |
| `app/` | Codigo de la API y del frontend |
| `_bicep-para-mas-adelante/` | Primer borrador declarativo. Aparcado hasta dominar los comandos |

## Como se abre la guia

```bash
xdg-open guia/index.html
```

## Coste

Disenada para costar practicamente cero: sin Application Gateway, sin endpoints
privados de pago y sin registro de imagenes propio. Ver la seccion "Que cambia
respecto al Proyecto01" en la guia.
