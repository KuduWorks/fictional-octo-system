@description('The name of the virtual network')
param vnetName string = 'vnet-${uniqueString(resourceGroup().id)}'

@description('The address prefix for the virtual network')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('The name of the subnet')
param subnetName string = 'default'

@description('The address prefix for the subnet')
param subnetAddressPrefix string = '10.0.1.0/24'

@description('The Azure region where resources will be deployed')
param location string = resourceGroup().location

@description('Tags to apply to all resources')
param tags object = {
  Environment: 'Development'
  Project: 'fictional-octo-system'
  ManagedBy: 'Bicep'
}

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-04-01' = {
  name: 'nsg-${vnetName}'
  location: location
  tags: tags
  properties: {
    securityRules: [
      {
        name: 'AllowHTTPS'
        properties: {
          description: 'Allow HTTPS traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSSH'
        properties: {
          description: 'Allow SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
    ]
  }
}

@description('The resource ID of the virtual network')
output vnetId string = vnet.id

@description('The name of the virtual network')
output vnetName string = vnet.name

@description('The address prefix of the virtual network')
output vnetAddressPrefix string = vnetAddressPrefix

@description('The resource ID of the subnet')
output subnetId string = vnet.properties.subnets[0].id

@description('The name of the subnet')
output subnetName string = subnetName

@description('The address prefix of the subnet')
output subnetAddressPrefix string = subnetAddressPrefix

@description('The resource ID of the network security group')
output nsgId string = nsg.id

@description('The name of the network security group')
output nsgName string = nsg.name
