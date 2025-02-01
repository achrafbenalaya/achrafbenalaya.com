# Login to Azure
# Connect-AzAccount

# Get all App Services in the subscription with Linux plan
$linuxAppServices = Get-AzWebApp | Where-Object { $_.Kind -eq 'app' }

# Filter by app services that have the tag "category" with value "Demo" and not in the tag "Lifecycle" with value "Persistent"
$linuxAppServices = $linuxAppServices | Where-Object { $_.Tags['category'] -eq 'Demo' -and $_.Tags['Lifecycle'] -ne 'Persistent' }

# Function to stop and delete an App Service and its App Service Plan
function Stop-And-Delete-AppService {
    param (
        [Parameter(Mandatory = $true)]
        $appService
    )

    if ($appService.State -eq 'Running') {
        Write-Output "Stopping App Service: $($appService.Name)"
        Stop-AzWebApp -ResourceGroupName $appService.ResourceGroup -Name $appService.Name -Force
        Write-Output "App Service $($appService.Name) stopped successfully"
    }

    Write-Output "Deleting App Service: $($appService.Name)"
    Remove-AzWebApp -ResourceGroupName $appService.ResourceGroup -Name $appService.Name -Force
    Write-Output "App Service $($appService.Name) deleted successfully"

    Write-Output "Deleting App Service Plan: $($appService.AppServicePlan)"
    Remove-AzAppServicePlan -ResourceGroupName $appService.ResourceGroup -Name $appService.AppServicePlan -Force
    Write-Output "App Service Plan $($appService.AppServicePlan) deleted successfully"
}

# Stop and delete the filtered App Services and their App Service Plans
$linuxAppServices | ForEach-Object { Stop-And-Delete-AppService -appService $_ }