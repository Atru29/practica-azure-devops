// =====================================================================
//  Red virtual y subredes
//
//  Dos subredes, cada una DELEGADA a un servicio. Delegar significa
//  cederle a Azure el control de esa subred: solo ese servicio puede
//  poner recursos dentro, y a cambio puede inyectar sus propias
//  maquinas sin que nosotros las veamos.
//
//  Equivalente imperativo:
//    az network vnet create --name vnet-demo01-dev ...
//    az network vnet subnet create --name snet-apps ... --delegations Microsoft.App/environments
// =====================================================================

@description('Sufijo comun de nombres, por ejemplo demo01-dev.')
param sufijo string

@description('Region de Azure.')
param ubicacion string

@description('Espacio de direcciones completo de la red.')
param espacio string = '10.50.0.0/16'

@description('Subred de Container Apps. Debe ser /23 como minimo.')
param rangoApps string = '10.50.0.0/23'

@description('Subred de PostgreSQL. Queda reservada por completo al servidor.')
param rangoPostgres string = '10.50.2.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: 'vnet-${sufijo}'
  location: ubicacion
  properties: {
    addressSpace: {
      addressPrefixes: [ espacio ]
    }
    subnets: [
      {
        // Aqui vive el entorno de Container Apps. El /23 no es capricho:
        // el modelo de consumo reserva direcciones para sus propias
        // instancias internas y Azure rechaza nada mas pequeno.
        name: 'snet-apps'
        properties: {
          addressPrefix: rangoApps
          delegations: [
            {
              name: 'delegacion-container-apps'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
        // El servidor de PostgreSQL se inyecta aqui dentro. Al estar
        // delegada, el servidor NO tiene nombre publico: solo se alcanza
        // desde dentro de esta red. Es el equivalente correcto de las
        // maquinas sin IP publica del Proyecto01, y no cuesta nada extra.
        name: 'snet-postgres'
        properties: {
          addressPrefix: rangoPostgres
          delegations: [
            {
              name: 'delegacion-postgres'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

output idRed string = vnet.id
output nombreRed string = vnet.name
output idSubredApps string = vnet.properties.subnets[0].id
output idSubredPostgres string = vnet.properties.subnets[1].id
