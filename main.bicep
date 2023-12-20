
targetScope = 'resourceGroup'
param location string = resourceGroup().location

@minLength(1)
@maxLength(64)
@description('Name of containerapp')
param appName string

@minLength(1)
@maxLength(64)
@description('Container environment name')
param containerAppsEnvironmentName string

@description('Container registry username')
param registryUsername string

@secure()
@description('Container registry password')
param registryPassword string

var registryPasswordRef = 'container-registry-password'
@allowed([
  'blue'
  'green'
])
@description('Name of the label that gets 100% of the traffic')
param productionLabel string
@description('BuildId') 
param buildID string

@minLength(1)
@maxLength(64)
@description('CommitId for blue revision')
param blueCommitID string

@maxLength(64)
@description('CommitId for green revision')
param greenCommitID string = ''


@maxLength(64)
@description('CommitId for the latest deployed revision')
param latestCommitId string 


resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
}
}
resource blueGreenDeploymentApp 'Microsoft.App/containerApps@2023-05-01' = {
  name: appName
  location: location
  tags: {
    blueCommitID: blueCommitID
    greenCommitID: greenCommitID
    latestCommitId: latestCommitId
    productionLabel: productionLabel
  }
  properties: {
    configuration: {
      activeRevisionsMode: 'multiple'
      ingress: {
        external: true
        targetPort: 3000 
        traffic: !empty(blueCommitID) && !empty(greenCommitID)  ? [
          {
            revisionName: '${appName}--${greenCommitID}'
            label: 'green'
            weight: productionLabel == 'green' ? 100 : 0
          }
          {
            revisionName: '${appName}--${blueCommitID}'
            label: 'blue'
            weight: productionLabel == 'blue' ? 100 : 0
          }
        ] :[
          {
            revisionName: '${appName}--${blueCommitID}'
            label: 'blue'
            weight: 100
          }
        ]
      }
      maxInactiveRevisions: 10 // remove old inactive revisions, depends on company policy and how many revisions you want to keep
      registries: [
        {
          passwordSecretRef: registryPasswordRef
          server: 'registry.hub.docker.com'
          username: registryUsername
        }
      ]
      secrets: [
        {
          name: registryPasswordRef
          value: registryPassword
        }
      ]
    }
    environmentId:  containerAppsEnvironment.id
    template: {
      containers: [
        {
          env: [
            {
              name: 'string'
              value: 'string'
            }
          ]
          image: 'registry.hub.docker.com/nkiboi/aca-example:${buildID}'
          name: appName
        }
      ]
      revisionSuffix: latestCommitId
    }
  }

}

output containerAppFQDN string = blueGreenDeploymentApp.properties.configuration.ingress.fqdn
output latestRevisionName string = blueGreenDeploymentApp.properties.latestRevisionName

