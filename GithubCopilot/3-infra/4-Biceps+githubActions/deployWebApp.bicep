param webAppName string = uniqueString(resourceGroup().id) // Generate unique String for web app name
param sku string = 'F1' // The SKU of App Service Plan
param linuxFxVersion string = 'node|14-lts' // The runtime stack of web app
param location string = resourceGroup().location // Location for all resources
param repositoryUrl string = 'https://github.com/Azure-Samples/nodejs-docs-hello-world'
param branch string = 'main'
var appServicePlanName = toLower('AppServicePlan-${webAppName}')
var webSiteName1 = toLower('wapp1-${webAppName}')
var webSiteName2 = toLower('wapp2-${webAppName}')

resource appServicePlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  properties: {
    reserved: true
  }
  sku: {
    name: sku
  }
  kind: 'linux'
}

resource appService1 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName1
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

var webSiteName3 = toLower('wapp3-${webAppName}')

resource appService3 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName3
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

resource srcControls3 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${appService3.name}/web'
  properties: {
    repoUrl: repositoryUrl
    branch: branch
    isManualIntegration: true
  }
}



resource appService2 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName2
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: linuxFxVersion
    }
  }
}

resource srcControls1 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${appService1.name}/web'
  properties: {
    repoUrl: repositoryUrl
    branch: branch
    isManualIntegration: true
  }
}

resource srcControls2 'Microsoft.Web/sites/sourcecontrols@2021-01-01' = {
  name: '${appService2.name}/web'
  properties: {
    repoUrl: repositoryUrl
    branch: branch
    isManualIntegration: true
  }
}
