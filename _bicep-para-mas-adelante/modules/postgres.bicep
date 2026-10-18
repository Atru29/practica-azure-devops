// =====================================================================
//  PostgreSQL Flexible Server con ACCESO PRIVADO
//
//  El servidor se inyecta dentro de la subred delegada: no tiene
//  nombre publico ni reglas de cortafuegos que mantener. Solo lo
//  alcanza quien este dentro de la red virtual.
//
//  Esto se decide AL CREARLO y no se puede cambiar despues. Pasar de
//  publico a privado exige borrar el servidor y rehacerlo.
//
//  Equivalente imperativo:
//    az postgres flexible-server create \
//      --resource-group rg-demo01-dev \
//      --name pg-demo01-dev \
//      --location eastus \
//      --tier Burstable \
//      --sku-name Standard_B1ms \
//      --storage-size 32 \
//      --version 16 \
//      --vnet vnet-demo01-dev \
//      --subnet snet-postgres \
//      --private-dns-zone demo01.private.postgres.database.azure.com
// =====================================================================

@description('Sufijo comun de nombres.')
param sufijo string

@description('Region de Azure.')
param ubicacion string

@description('Id de la subred delegada a PostgreSQL.')
param idSubred string

@description('Id de la red virtual, para enlazar la zona DNS privada.')
param idRed string

@description('Usuario administrador.')
param usuarioAdmin string = 'pgadmin'

@secure()
@description('Contrasena del administrador. Nunca se escribe en el fichero.')
param claveAdmin string

@description('Nombre de la base de datos de la aplicacion.')
param nombreBaseDatos string = 'appdb'

// B1ms: 1 vCPU y 2 GB. Es el tamano que cubren las 750 horas
// gratuitas de los primeros 12 meses, o sea un mes entero encendido.
var sku = 'Standard_B1ms'

// Sin esta zona, el nombre del servidor no resuelve desde dentro de la
// red. Es la pieza que mas se olvida al montar acceso privado a mano.
resource zonaDns 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'pg-${sufijo}.private.postgres.database.azure.com'
  location: 'global'
}

resource enlaceZona 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: zonaDns
  name: 'enlace-${sufijo}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: idRed
    }
    registrationEnabled: false
  }
}

resource servidor 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: 'pg-${sufijo}'
  location: ubicacion
  sku: {
    name: sku
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    administratorLogin: usuarioAdmin
    administratorLoginPassword: claveAdmin
    storage: {
      storageSizeGB: 32
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: idSubred
      privateDnsZoneArmResourceId: zonaDns.id
    }
    highAvailability: {
      mode: 'Disabled'
    }
  }
  dependsOn: [
    enlaceZona
  ]
}

resource baseDatos 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: servidor
  name: nombreBaseDatos
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

output nombreServidor string = servidor.name
output fqdn string = servidor.properties.fullyQualifiedDomainName
output baseDatos string = baseDatos.name
