// =====================================================================
//  PracticaLaboratorios - topologia completa
//
//  Backend .NET en contenedor, frontend Angular estatico, PostgreSQL
//  privado. Pensada para costar lo minimo: sin Application Gateway,
//  sin endpoints privados de pago y sin registro propio.
//
//  Se despliega sobre un grupo de recursos que ya exista:
//    az deployment group create \
//      --resource-group rg-demo01-dev \
//      --template-file infra/main.bicep \
//      --parameters pgPassword='...'
// =====================================================================

targetScope = 'resourceGroup'

@description('Nombre corto del proyecto. Prefijo de todos los recursos.')
param proyecto string = 'demo01'

@description('Entorno al que pertenece este despliegue.')
@allowed([ 'dev', 'qa', 'prod' ])
param entorno string = 'dev'

@description('Region. Por defecto la del grupo de recursos.')
param ubicacion string = resourceGroup().location

var sufijo = '${proyecto}-${entorno}'

module red 'modules/red.bicep' = {
  name: 'desplegar-red'
  params: {
    sufijo: sufijo
    ubicacion: ubicacion
  }
}

output idSubredApps string = red.outputs.idSubredApps
output idSubredPostgres string = red.outputs.idSubredPostgres
