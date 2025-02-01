# Define variables
$resourceGroups = @("dev-rg", "acceptance-rg", "production-rg")
$location = "France Central"
$sku = "B1"
$tagsDevAcceptance = @{
    "cloud advocate" = "Acharf Ben Alaya"
    "category" = "Demo"
}
$tagsProduction = @{
    "cloud advocate" = "Achraf Ben Alaya"
    "category" = "Demo"
    "Lifecycle" = "Persistent"
}

# Function to generate a random name
function Get-RandomName {
    $prefix = "appservice"
    $suffix = Get-Random -Minimum 1000 -Maximum 9999
    return "$prefix$suffix"
}

# Login to Azure
# Connect-AzAccount

# Create resource groups
foreach ($rg in $resourceGroups) {
    New-AzResourceGroup -Name $rg -Location $location
}

# Create App Services and App Service Plans in dev and acceptance resource groups
foreach ($rg in $resourceGroups[0..1]) {
    for ($i = 1; $i -le 2; $i++) {
        $appServiceName = Get-RandomName
        $appServicePlanName = "$appServiceName-plan"
        New-AzAppServicePlan -ResourceGroupName $rg -Name $appServicePlanName -Location $location -Tier $sku -Tag $tagsDevAcceptance
        New-AzWebApp -ResourceGroupName $rg -Name $appServiceName -Location $location -AppServicePlan $appServicePlanName -Tag $tagsDevAcceptance
    }
}

# Create App Services and App Service Plans in production resource group
foreach ($rg in $resourceGroups[2..2]) {
    for ($i = 1; $i -le 2; $i++) {
        $appServiceName = Get-RandomName
        $appServicePlanName = "$appServiceName-plan"
        New-AzAppServicePlan -ResourceGroupName $rg -Name $appServicePlanName -Location $location -Tier $sku -Tag $tagsProduction
        New-AzWebApp -ResourceGroupName $rg -Name $appServiceName -Location $location -AppServicePlan $appServicePlanName -Tag $tagsProduction
    }
}