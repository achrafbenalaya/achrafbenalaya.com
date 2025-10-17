param(
    [Parameter(Mandatory=$false)]
    [string]$WorkspaceName,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [switch]$AllWorkspaces,
    
    [Parameter(Mandatory=$false)]
    [string[]]$SubscriptionIds,
    
    [Parameter(Mandatory=$false)]
    [int]$DaysBack = 30,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputDirectory = ".\LAWorkspaceAudits_$(Get-Date -Format 'yyyyMMdd_HHmmss')",
    
    [Parameter(Mandatory=$false)]
    [int]$MaxConcurrency = 5,
    
    [Parameter(Mandatory=$false)]
    [switch]$GenerateSummaryReport
)

# Import required modules
$RequiredModules = @("Az.Accounts", "Az.Resources", "Az.Monitor", "Az.OperationalInsights", "Az.CostManagement")
foreach ($Module in $RequiredModules) {
    try {
        Import-Module $Module -Force -ErrorAction Stop
        Write-Host "[INFO] Loaded module: $Module" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to load required module: $Module. Please install it using: Install-Module $Module"
        exit 1
    }
}

function Write-Log {
    param(
        [string]$Message, 
        [string]$Level = "INFO",
        [string]$WorkspaceName = ""
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = if ($WorkspaceName) { "[$WorkspaceName]" } else { "" }
    Write-Host "[$timestamp]$prefix [$Level] $Message" -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "SUCCESS" { "Green" }
            "INFO" { "Cyan" }
            "PROGRESS" { "Magenta" }
            default { "White" }
        }
    )
}

function Get-AllLogAnalyticsWorkspaces {
    param([string[]]$TargetSubscriptionIds = @())
    
    Write-Log "Discovering Log Analytics workspaces across subscriptions..."
    
    $allWorkspaces = @()
    $subscriptions = @()
    
    if ($TargetSubscriptionIds.Count -gt 0) {
        foreach ($subId in $TargetSubscriptionIds) {
            try {
                $sub = Get-AzSubscription -SubscriptionId $subId -ErrorAction Stop
                $subscriptions += $sub
            }
            catch {
                Write-Log "Cannot access subscription $subId : $($_.Exception.Message)" -Level "WARNING"
            }
        }
    }
    else {
        $subscriptions = Get-AzSubscription
    }
    
    Write-Log "Found $($subscriptions.Count) accessible subscriptions"
    
    foreach ($subscription in $subscriptions) {
        try {
            Write-Log "Checking subscription: $($subscription.Name) ($($subscription.Id))"
            Set-AzContext -SubscriptionId $subscription.Id | Out-Null
            
            $workspaces = Get-AzOperationalInsightsWorkspace
            
            foreach ($workspace in $workspaces) {
                $allWorkspaces += [PSCustomObject]@{
                    WorkspaceName = $workspace.Name
                    ResourceGroupName = $workspace.ResourceGroupName
                    SubscriptionId = $subscription.Id
                    SubscriptionName = $subscription.Name
                    Location = $workspace.Location
                    CustomerId = $workspace.CustomerId
                    ResourceId = $workspace.ResourceId
                    Sku = $workspace.Sku
                    RetentionInDays = $workspace.RetentionInDays
                    CreatedDate = $workspace.CreatedDate
                    WorkspaceObject = $workspace
                }
            }
            
            Write-Log "Found $($workspaces.Count) workspaces in subscription $($subscription.Name)" -Level "SUCCESS"
        }
        catch {
            Write-Log "Error accessing subscription $($subscription.Name): $($_.Exception.Message)" -Level "WARNING"
        }
    }
    
    Write-Log "Total workspaces discovered: $($allWorkspaces.Count)" -Level "SUCCESS"
    return $allWorkspaces
}

function Get-HtmlTemplate {
    param($WorkspaceName, $SubscriptionName, $GeneratedDate, $DaysBack, $Content)
    
    return @"
<!DOCTYPE html>
<html>
<head>
    <title>Log Analytics Workspace Audit Report - $WorkspaceName</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background-color: #f8f9fa; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px; border-radius: 8px; margin-bottom: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .section { background: white; margin-bottom: 25px; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
        .section h2 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 8px; margin-top: 0; }
        .warning { background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%); border-left: 4px solid #f39c12; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .success { background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%); border-left: 4px solid #27ae60; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .error { background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%); border-left: 4px solid #e74c3c; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .critical { background: linear-gradient(135deg, #fadbd8 0%, #f1948a 100%); border-left: 4px solid #c0392b; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .info { background: linear-gradient(135deg, #d1ecf1 0%, #bee5eb 100%); border-left: 4px solid #17a2b8; padding: 15px; border-radius: 5px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 12px 8px; text-align: left; }
        th { background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; font-weight: 600; }
        tr:nth-child(even) { background-color: #f8f9fa; }
        tr:hover { background-color: #e8f4fd; }
        .summary { background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%); padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #2196f3; }
        .metric { display: inline-block; background: #6c757d; color: white; padding: 4px 8px; border-radius: 12px; font-size: 12px; margin-right: 5px; }
        .badge-high { background: #dc3545; }
        .badge-medium { background: #fd7e14; }
        .badge-low { background: #28a745; }
        .query-result { background-color: #f8f9fa; border: 1px solid #dee2e6; border-radius: 4px; padding: 10px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Log Analytics Workspace Audit Report</h1>
        <p><strong>Workspace:</strong> $WorkspaceName</p>
        <p><strong>Subscription:</strong> $SubscriptionName</p>
        <p><strong>Generated:</strong> $GeneratedDate</p>
        <p><strong>Analysis Period:</strong> Last $DaysBack days</p>
    </div>
    $Content
</body>
</html>
"@
}

function Get-SummaryHtmlTemplate {
    param($TotalWorkspaces, $GeneratedDate, $DaysBack, $Content)
    
    return @"
<!DOCTYPE html>
<html>
<head>
    <title>Log Analytics Workspaces Summary Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background-color: #f8f9fa; }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 25px; border-radius: 8px; margin-bottom: 25px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); }
        .section { background: white; margin-bottom: 25px; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.05); }
        .section h2 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 8px; margin-top: 0; }
        .warning { background: linear-gradient(135deg, #fff3cd 0%, #ffeaa7 100%); border-left: 4px solid #f39c12; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .success { background: linear-gradient(135deg, #d4edda 0%, #c3e6cb 100%); border-left: 4px solid #27ae60; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .error { background: linear-gradient(135deg, #f8d7da 0%, #f5c6cb 100%); border-left: 4px solid #e74c3c; padding: 15px; border-radius: 5px; margin: 10px 0; }
        .critical { background: linear-gradient(135deg, #fadbd8 0%, #f1948a 100%); border-left: 4px solid #c0392b; padding: 15px; border-radius: 5px; margin: 10px 0; }
        table { border-collapse: collapse; width: 100%; margin: 15px 0; font-size: 14px; }
        th, td { border: 1px solid #ddd; padding: 12px 8px; text-align: left; }
        th { background: linear-gradient(135deg, #34495e 0%, #2c3e50 100%); color: white; font-weight: 600; }
        tr:nth-child(even) { background-color: #f8f9fa; }
        tr:hover { background-color: #e8f4fd; }
        .summary { background: linear-gradient(135deg, #e3f2fd 0%, #bbdefb 100%); padding: 20px; border-radius: 8px; margin: 25px 0; border-left: 4px solid #2196f3; }
        .workspace-card { background: white; border: 1px solid #e9ecef; border-radius: 6px; padding: 15px; margin: 10px 0; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        .risk-critical { border-left: 4px solid #c0392b; }
        .risk-high { border-left: 4px solid #e74c3c; }
        .risk-medium { border-left: 4px solid #f39c12; }
        .risk-low { border-left: 4px solid #27ae60; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Log Analytics Workspaces Summary Report</h1>
        <p><strong>Total Workspaces Analyzed:</strong> $TotalWorkspaces</p>
        <p><strong>Generated:</strong> $GeneratedDate</p>
        <p><strong>Analysis Period:</strong> Last $DaysBack days</p>
    </div>
    $Content
</body>
</html>
"@
}

function Convert-ToHtmlTable {
    param([array]$Data)
    
    if (-not $Data -or $Data.Count -eq 0) {
        return "<p><em>No data found</em></p>"
    }
    
    $html = "<table>"
    # Headers
    $properties = $Data[0].PSObject.Properties.Name
    $html += "<tr>"
    foreach ($prop in $properties) {
        $html += "<th>$prop</th>"
    }
    $html += "</tr>"
    # Data rows
    foreach ($item in $Data) {
        $html += "<tr>"
        foreach ($prop in $properties) {
            $value = $item.$prop
            if ($value -eq $null) { $value = "" }
            if ($prop -match "(LastSeen|FirstSeen|Timestamp|Date)" -and $value -ne "") {
                try {
                    $value = ([datetime]$value).ToString("yyyy-MM-dd HH:mm:ss")
                }
                catch { }
            }
            elseif ($prop -eq "RecordCount" -and $value -ne "" -and [int]::TryParse($value, [ref]$null)) {
                $value = "{0:N0}" -f [int]$value
            }
            elseif ($prop -eq "Cost" -and $value -ne "") {
                $value = "{0:N2} €" -f [double]$value
            }
            $html += "<td>$value</td>"
        }
        $html += "</tr>"
    }
    $html += "</table>"
    return $html
}

function Get-WorkspaceLogAnalyticsCostLast30Days {
    param([object]$WorkspaceInfo)

    $subscriptionId = $WorkspaceInfo.SubscriptionId
    $workspaceName = $WorkspaceInfo.WorkspaceName
    $resourceGroup = $WorkspaceInfo.ResourceGroupName

    try {
        Set-AzContext -SubscriptionId $subscriptionId | Out-Null

        # Get all usage details for the subscription in the last 30 days
        $allUsageDetails = Get-AzConsumptionUsageDetail -StartDate (Get-Date).AddDays(-30).ToString('yyyy-MM-dd') -EndDate (Get-Date).ToString('yyyy-MM-dd') -ErrorAction Stop

        # Filter for resources that belong to the Log Analytics workspace (check the resource group and name)
        # CostManagement data may have resourceId in different cases, so use case-insensitive match
        $filteredUsage = $allUsageDetails | Where-Object {
            $_.ResourceId -and ($_.ResourceId.ToLower() -like "*Microsoft.OperationalInsights/workspaces/$($workspaceName.ToLower())*")
        }

        # Aggregate cost by date
        $costSummary = $filteredUsage | Group-Object UsageDate | ForEach-Object {
            [PSCustomObject]@{
                Date = $_.Name
                Cost = ($_.Group | Measure-Object -Property PreTaxCost -Sum).Sum
            }
        } | Sort-Object Date

        return $costSummary
    }
    catch {
        Write-Log "Unable to retrieve cost for workspace $workspaceName : $($_.Exception.Message)" -Level "WARNING"
        return @()
    }
}

function Invoke-SafeLogAnalyticsQuery {
    param(
        [object]$Workspace,
        [string]$Query,
        [string]$QueryDescription = "Query"
    )
    try {
        $result = Invoke-AzOperationalInsightsQuery -Workspace $Workspace -Query $Query -ErrorAction Stop
        return $result.Results
    }
    catch {
        Write-Log "$QueryDescription failed: $($_.Exception.Message)" -Level "WARNING" -WorkspaceName $Workspace.Name
        return $null
    }
}

function Get-AvailableTables {
    param([object]$Workspace)
    $query = "search * | getschema | distinct TableName | limit 100"
    $result = Invoke-SafeLogAnalyticsQuery -Workspace $Workspace -Query $query -QueryDescription "Table Discovery"
    if ($result -and $result.Count -gt 0) {
        return $result | Select-Object -ExpandProperty TableName | Sort-Object
    }
    # Fallback: Test common tables
    $commonTables = @(
        "AppMetrics", "AppPerformanceCounters", "AppRequests", "AppExceptions", "AppTraces", "AppEvents",
        "AzureActivity", "SecurityEvent", "Syslog", "Event", "Heartbeat", "Perf", "WindowsEvent", "Usage"
    )
    $availableTables = @()
    foreach ($table in $commonTables) {
        $testResult = Invoke-SafeLogAnalyticsQuery -Workspace $Workspace -Query "$table | take 1" -QueryDescription "Testing $table"
        if ($testResult -ne $null) {
            $availableTables += $table
        }
    }
    return $availableTables
}

function Get-DiagnosticSettingsResources {
    param([string]$WorkspaceId)
    $resourceTypes = @(
        "Microsoft.Web/sites",                # App Service
        "Microsoft.Logic/workflows",          # Logic App
        "Microsoft.Web/sites/functions",      # Function App
        "Microsoft.Compute/virtualMachines",
        "Microsoft.Sql/servers"
    )
    $diagnosticResources = @()
    foreach ($resourceType in $resourceTypes) {
        $resources = Get-AzResource -ResourceType $resourceType -ErrorAction SilentlyContinue
        foreach ($resource in $resources) {
            $settings = Get-AzDiagnosticSetting -ResourceId $resource.ResourceId -ErrorAction SilentlyContinue
            foreach ($setting in $settings) {
                if ($setting.WorkspaceId -eq $WorkspaceId) {
                    $diagnosticResources += [PSCustomObject]@{
                        ResourceName      = $resource.Name
                        ResourceType      = $resource.ResourceType
                        ResourceGroup     = $resource.ResourceGroupName
                        DiagnosticSetting = $setting.Name
                    }
                }
            }
        }
    }
    return $diagnosticResources
}

function Get-WorkspaceAuditData {
    param([object]$WorkspaceInfo, [int]$DaysBack)
    $workspace = $WorkspaceInfo.WorkspaceObject
    Write-Log "Starting audit of workspace: $($workspace.Name)" -Level "PROGRESS" -WorkspaceName $workspace.Name
    Set-AzContext -SubscriptionId $WorkspaceInfo.SubscriptionId | Out-Null
    $availableTables = Get-AvailableTables -Workspace $workspace
    Write-Log "Found $($availableTables.Count) tables" -WorkspaceName $workspace.Name
    $dataSources = @()
    $appInsightsData = @()
    foreach ($table in $availableTables) {
        $query = @"
$table
| where TimeGenerated > ago($($DaysBack)d)
| summarize 
    RecordCount = count(),
    LastSeen = max(TimeGenerated),
    FirstSeen = min(TimeGenerated)
| extend TableName = '$table'
"@
        $result = Invoke-SafeLogAnalyticsQuery -Workspace $workspace -Query $query -QueryDescription "Analyzing $table"
        if ($result -and $result.Count -gt 0 -and $result[0].RecordCount -gt 0) {
            $dataSource = $result[0]
            $dataSource | Add-Member -NotePropertyName "DaysActive" -NotePropertyValue ([math]::Max(1, [math]::Ceiling((([datetime]$dataSource.LastSeen) - ([datetime]$dataSource.FirstSeen)).TotalDays)))
            if ($table -match "^App") {
                $appInsightsData += $dataSource
            } else {
                $dataSources += $dataSource
            }
        }
    }

    # Get Log Analytics cost last 30 days (adjusted)
    $costLast30Days = Get-WorkspaceLogAnalyticsCostLast30Days -WorkspaceInfo $WorkspaceInfo

    # Get diagnostic settings with detailed resource types
    $diagnosticSettings = Get-DiagnosticSettingsResources -WorkspaceId $workspace.ResourceId

    # Alerts
    Write-Log "Checking alerts..." -WorkspaceName $workspace.Name
    $alerts = @()
    try {
        $alertRules = Get-AzResource -ResourceType "Microsoft.Insights/scheduledQueryRules" -ErrorAction SilentlyContinue
        foreach ($alertRule in $alertRules) {
            try {
                $rule = Get-AzResource -ResourceId $alertRule.ResourceId -ErrorAction SilentlyContinue
                if ($rule.Properties.scopes -contains $workspace.ResourceId) {
                    $alerts += [PSCustomObject]@{
                        Name = $rule.Name
                        ResourceGroup = $rule.ResourceGroupName
                        Enabled = $rule.Properties.enabled
                        Severity = $rule.Properties.severity
                    }
                }
            }
            catch { }
        }
    }
    catch {
        Write-Log "Error checking alerts: $($_.Exception.Message)" -Level "WARNING" -WorkspaceName $workspace.Name
    }

    $riskLevel = "LOW"
    $risks = @()
    if ($dataSources.Count -gt 0 -or $appInsightsData.Count -gt 0) {
        $totalDataSources = $dataSources.Count + $appInsightsData.Count
        $risks += "$totalDataSources active data tables"
        $riskLevel = "MEDIUM"
    }
    if ($diagnosticSettings.Count -gt 0) {
        $risks += "$($diagnosticSettings.Count) diagnostic settings"
        $riskLevel = "HIGH"
    }
    if ($alerts.Count -gt 0) {
        $risks += "$($alerts.Count) alerts"
        $riskLevel = "CRITICAL"
    }
    Write-Log "Audit completed. Risk Level: $riskLevel" -Level "SUCCESS" -WorkspaceName $workspace.Name
    return [PSCustomObject]@{
        WorkspaceInfo      = $WorkspaceInfo
        AvailableTables    = $availableTables
        DataSources        = $dataSources
        AppInsightsData    = $appInsightsData
        DiagnosticSettings = $diagnosticSettings
        Alerts             = $alerts
        RiskLevel          = $riskLevel
        Risks              = $risks
        TotalDataTables    = $dataSources.Count + $appInsightsData.Count
        AuditTimestamp     = Get-Date
        CostLast30Days     = $costLast30Days
    }
}

function Generate-WorkspaceReport {
    param([object]$AuditData, [string]$OutputDirectory)
    $workspaceInfo = $AuditData.WorkspaceInfo
    $workspaceName = $workspaceInfo.WorkspaceName
    $subscriptionName = $workspaceInfo.SubscriptionName
    $reportContent = ""
    # Workspace type detection
    $workspaceType = if ($AuditData.AppInsightsData.Count -gt 0) { "Application Insights / Log Analytics" } else { "Log Analytics" }
    # Summary
    $reportContent += "<div class='summary'>"
    $reportContent += "<h2>DELETION IMPACT SUMMARY</h2>"
    $reportContent += "<p><strong>WORKSPACE TYPE:</strong> $workspaceType</p>"
    $reportContent += "<p><strong>RISK LEVEL: <span style='color: $(switch($AuditData.RiskLevel) { 'LOW' {'#27ae60'} 'MEDIUM' {'#f39c12'} 'HIGH' {'#e74c3c'} 'CRITICAL' {'#c0392b'} })'>$($AuditData.RiskLevel)</span></strong></p>"
    if ($AuditData.Risks.Count -gt 0) {
        $reportContent += "<ul>"
        foreach ($risk in $AuditData.Risks) {
            $reportContent += "<li>$risk will be affected</li>"
        }
        $reportContent += "</ul>"
    } else {
        $reportContent += "<p style='color: #27ae60; font-weight: bold;'>No major dependencies found. Workspace appears safe to delete.</p>"
    }
    $reportContent += "</div>"
    # Workspace Details
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Workspace Details</h2>"
    $workspaceDetails = @(
        [PSCustomObject]@{Property="Name"; Value=$workspaceInfo.WorkspaceName}
        [PSCustomObject]@{Property="Subscription"; Value=$workspaceInfo.SubscriptionName}
        [PSCustomObject]@{Property="Resource Group"; Value=$workspaceInfo.ResourceGroupName}
        [PSCustomObject]@{Property="Location"; Value=$workspaceInfo.Location}
        [PSCustomObject]@{Property="SKU"; Value=$workspaceInfo.Sku}
        [PSCustomObject]@{Property="Retention (Days)"; Value=$workspaceInfo.RetentionInDays}
        [PSCustomObject]@{Property="Available Tables"; Value=$AuditData.AvailableTables.Count}
    )
    $reportContent += Convert-ToHtmlTable -Data $workspaceDetails
    $reportContent += "</div>"
    # Available Tables
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Available Data Tables</h2>"
    $reportContent += "<div class='query-result'>"
    $reportContent += "<p><strong>Total Tables:</strong> $($AuditData.AvailableTables.Count)</p>"
    $reportContent += "<p><strong>Tables:</strong> $($AuditData.AvailableTables -join ', ')</p>"
    $reportContent += "</div>"
    $reportContent += "</div>"
    # Data Sources
    if ($AuditData.DataSources.Count -gt 0) {
        $reportContent += "<div class='section'>"
        $reportContent += "<h2>Active Data Sources</h2>"
        $reportContent += "<div class='warning'>These data tables are actively receiving data.</div>"
        $reportContent += Convert-ToHtmlTable -Data $AuditData.DataSources
        $reportContent += "</div>"
    }
    # Application Insights Data
    if ($AuditData.AppInsightsData.Count -gt 0) {
        $reportContent += "<div class='section'>"
        $reportContent += "<h2>Application Insights Data</h2>"
        $reportContent += "<div class='warning'>These Application Insights tables contain telemetry data.</div>"
        $reportContent += Convert-ToHtmlTable -Data $AuditData.AppInsightsData
        $reportContent += "</div>"
    }
    # Cost Section
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Log Analytics Cost (Last 30 Days)</h2>"
    if ($AuditData.CostLast30Days.Count -gt 0) {
        $costRows = $AuditData.CostLast30Days | ForEach-Object {
            "<tr><td>$($_.Date)</td><td>$($_.Cost)</td></tr>"
        }
        $reportContent += "<table><tr><th>Date</th><th>Cost (€)</th></tr>$($costRows -join '')</table>"
    } else {
        $reportContent += "<div class='info'>Aucune donnée de coût trouvée pour les 30 derniers jours.</div>"
    }
    $reportContent += "</div>"
    # Diagnostic Resources Section
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Resources Sending Diagnostics to This Workspace</h2>"
    if ($AuditData.DiagnosticSettings.Count -gt 0) {
        $reportContent += Convert-ToHtmlTable -Data $AuditData.DiagnosticSettings
    } else {
        $reportContent += "<div class='success'>Aucune ressource active connectée en diagnostic.</div>"
    }
    $reportContent += "</div>"
    # Alerts
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Dependent Alerts</h2>"
    if ($AuditData.Alerts.Count -gt 0) {
        $reportContent += "<div class='critical'>CRITICAL: These alerts will stop working after deletion!</div>"
        $reportContent += Convert-ToHtmlTable -Data $AuditData.Alerts
    } else {
        $reportContent += "<div class='success'>No alerts found.</div>"
    }
    $reportContent += "</div>"
    # Generate final HTML
    $finalHtml = Get-HtmlTemplate -WorkspaceName $workspaceName -SubscriptionName $subscriptionName -GeneratedDate (Get-Date) -DaysBack $DaysBack -Content $reportContent
    $fileName = "$($workspaceName)_$($workspaceInfo.SubscriptionName -replace '[^a-zA-Z0-9]', '_')_audit.html"
    $filePath = Join-Path $OutputDirectory $fileName
    $finalHtml | Out-File -FilePath $filePath -Encoding UTF8
    Write-Log "Report saved: $filePath" -Level "SUCCESS" -WorkspaceName $workspaceName
    return $filePath
}

function Generate-SummaryReport {
    param([array]$AllAuditData, [string]$OutputDirectory)
    Write-Log "Generating summary report for $($AllAuditData.Count) workspaces..." -Level "PROGRESS"
    $reportContent = ""
    $criticalWorkspaces = $AllAuditData | Where-Object { $_.RiskLevel -eq "CRITICAL" }
    $highRiskWorkspaces = $AllAuditData | Where-Object { $_.RiskLevel -eq "HIGH" }
    $mediumRiskWorkspaces = $AllAuditData | Where-Object { $_.RiskLevel -eq "MEDIUM" }
    $lowRiskWorkspaces = $AllAuditData | Where-Object { $_.RiskLevel -eq "LOW" }
    $reportContent += "<div class='summary'>"
    $reportContent += "<h2>ENTERPRISE AUDIT SUMMARY</h2>"
    $reportContent += "<div style='display: flex; gap: 20px; flex-wrap: wrap;'>"
    $reportContent += "<div style='flex: 1; min-width: 200px;'>"
    $reportContent += "<h3 style='color: #c0392b;'>CRITICAL RISK: $($criticalWorkspaces.Count)</h3>"
    $reportContent += "<h3 style='color: #e74c3c;'>HIGH RISK: $($highRiskWorkspaces.Count)</h3>"
    $reportContent += "<h3 style='color: #f39c12;'>MEDIUM RISK: $($mediumRiskWorkspaces.Count)</h3>"
    $reportContent += "<h3 style='color: #27ae60;'>LOW RISK: $($lowRiskWorkspaces.Count)</h3>"
    $reportContent += "</div>"
    $reportContent += "</div>"
    $reportContent += "</div>"
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Workspace Details</h2>"
    foreach ($auditData in ($AllAuditData | Sort-Object { switch($_.RiskLevel) { "CRITICAL" {1} "HIGH" {2} "MEDIUM" {3} "LOW" {4} }})) {
        $workspaceInfo = $auditData.WorkspaceInfo
        $riskClass = "risk-" + $auditData.RiskLevel.ToLower()
        $reportContent += "<div class='workspace-card $riskClass'>"
        $reportContent += "<h3>$($workspaceInfo.WorkspaceName)</h3>"
        $reportContent += "<p><strong>Subscription:</strong> $($workspaceInfo.SubscriptionName)</p>"
        $reportContent += "<p><strong>Resource Group:</strong> $($workspaceInfo.ResourceGroupName)</p>"
        $reportContent += "<p><strong>Location:</strong> $($workspaceInfo.Location)</p>"
        $reportContent += "<p><strong>Risk Level:</strong> <span style='font-weight: bold; color: $(switch($auditData.RiskLevel) { 'LOW' {'#27ae60'} 'MEDIUM' {'#f39c12'} 'HIGH' {'#e74c3c'} 'CRITICAL' {'#c0392b'} })'>$($auditData.RiskLevel)</span></p>"
        $reportContent += "<p><strong>Data Tables:</strong> $($auditData.TotalDataTables)</p>"
        $reportContent += "<p><strong>Diagnostic Settings:</strong> $($auditData.DiagnosticSettings.Count)</p>"
        $reportContent += "<p><strong>Alerts:</strong> $($auditData.Alerts.Count)</p>"
        if ($auditData.Risks.Count -gt 0) {
            $reportContent += "<p><strong>Impact:</strong> $($auditData.Risks -join ', ')</p>"
        }
        $reportContent += "</div>"
    }
    $reportContent += "</div>"
    $summaryData = $AllAuditData | ForEach-Object {
        [PSCustomObject]@{
            WorkspaceName = $_.WorkspaceInfo.WorkspaceName
            Subscription = $_.WorkspaceInfo.SubscriptionName
            RiskLevel = $_.RiskLevel
            DataTables = $_.TotalDataTables
            DiagnosticSettings = $_.DiagnosticSettings.Count
            Alerts = $_.Alerts.Count
            Location = $_.WorkspaceInfo.Location
        }
    }
    $reportContent += "<div class='section'>"
    $reportContent += "<h2>Summary Table</h2>"
    $reportContent += Convert-ToHtmlTable -Data $summaryData
    $reportContent += "</div>"
    $finalHtml = Get-SummaryHtmlTemplate -TotalWorkspaces $AllAuditData.Count -GeneratedDate (Get-Date) -DaysBack $DaysBack -Content $reportContent
    $summaryPath = Join-Path $OutputDirectory "SUMMARY_AllWorkspaces.html"
    $finalHtml | Out-File -FilePath $summaryPath -Encoding UTF8
    Write-Log "Summary report saved: $summaryPath" -Level "SUCCESS"
    return $summaryPath
}

# MAIN EXECUTION
try {
    Write-Log "Starting Bulk Log Analytics Workspace Audit" -Level "PROGRESS"
    if (-not $AllWorkspaces -and -not $WorkspaceName) {
        Write-Log "You must specify either -AllWorkspaces or -WorkspaceName parameter" -Level "ERROR"
        Write-Host @"
USAGE EXAMPLES:
  # Audit all workspaces in all accessible subscriptions
  .\BulkLAWorkspaceAudit.ps1 -AllWorkspaces -GenerateSummaryReport

  # Audit all workspaces in specific subscriptions
  .\BulkLAWorkspaceAudit.ps1 -AllWorkspaces -SubscriptionIds @("sub-id-1", "sub-id-2") -GenerateSummaryReport

  # Audit a specific workspace
  .\BulkLAWorkspaceAudit.ps1 -WorkspaceName "MyWorkspace" -ResourceGroupName "MyRG"
"@ -ForegroundColor Yellow
        exit 1
    }
    $context = Get-AzContext
    if (-not $context) {
        Write-Log "Not logged in to Azure. Please run Connect-AzAccount first." -Level "ERROR"
        exit 1
    }
    Write-Log "Using Azure context: $($context.Account.Id) - $($context.Subscription.Name)"
    if (-not (Test-Path $OutputDirectory)) {
        New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
        Write-Log "Created output directory: $OutputDirectory" -Level "SUCCESS"
    }
    $workspacesToAudit = @()
    if ($AllWorkspaces) {
        $workspacesToAudit = Get-AllLogAnalyticsWorkspaces -TargetSubscriptionIds $SubscriptionIds
    } else {
        if ($SubscriptionId) {
            Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
        }
        if ($ResourceGroupName) {
            $workspace = Get-AzOperationalInsightsWorkspace -ResourceGroupName $ResourceGroupName -Name $WorkspaceName -ErrorAction Stop
        } else {
            $workspaces = Get-AzOperationalInsightsWorkspace | Where-Object { $_.Name -eq $WorkspaceName }
            if ($workspaces.Count -eq 0) {
                throw "Workspace not found"
            } elseif ($workspaces.Count -gt 1) {
                throw "Multiple workspaces found. Please specify ResourceGroupName."
            }
            $workspace = $workspaces[0]
        }
        $context = Get-AzContext
        $workspacesToAudit = @([PSCustomObject]@{
            WorkspaceName = $workspace.Name
            ResourceGroupName = $workspace.ResourceGroupName
            SubscriptionId = $context.Subscription.Id
            SubscriptionName = $context.Subscription.Name
            Location = $workspace.Location
            CustomerId = $workspace.CustomerId
            ResourceId = $workspace.ResourceId
            Sku = $workspace.Sku
            RetentionInDays = $workspace.RetentionInDays
            CreatedDate = $workspace.CreatedDate
            WorkspaceObject = $workspace
        })
    }
    if ($workspacesToAudit.Count -eq 0) {
        Write-Log "No workspaces found to audit" -Level "ERROR"
        exit 1
    }
    Write-Log "Found $($workspacesToAudit.Count) workspaces to audit" -Level "SUCCESS"
    $allAuditData = @()
    $currentWorkspace = 0
    foreach ($workspaceInfo in $workspacesToAudit) {
        $currentWorkspace++
        Write-Log "Progress: $currentWorkspace of $($workspacesToAudit.Count) - $($workspaceInfo.WorkspaceName)" -Level "PROGRESS"
        try {
            $auditData = Get-WorkspaceAuditData -WorkspaceInfo $workspaceInfo -DaysBack $DaysBack
            $reportPath = Generate-WorkspaceReport -AuditData $auditData -OutputDirectory $OutputDirectory
            $allAuditData += $auditData
            Write-Log "Completed: $($workspaceInfo.WorkspaceName)" -Level "SUCCESS"
        }
        catch {
            Write-Log "Failed to audit workspace $($workspaceInfo.WorkspaceName): $($_.Exception.Message)" -Level "ERROR"
        }
    }
    if ($GenerateSummaryReport -or $allAuditData.Count -gt 1) {
        $summaryPath = Generate-SummaryReport -AllAuditData $allAuditData -OutputDirectory $OutputDirectory
    }
    Write-Log "Audit completed successfully!" -Level "SUCCESS"
    Write-Log "Output directory: $OutputDirectory" -Level "SUCCESS"
    Write-Log "Workspaces audited: $($allAuditData.Count)" -Level "SUCCESS"
    $riskSummary = $allAuditData | Group-Object RiskLevel | ForEach-Object {
        "$($_.Name): $($_.Count)"
    }
    Write-Log "Risk distribution: $($riskSummary -join ', ')" -Level "INFO"
    try {
        Start-Process $OutputDirectory
    } catch {
        Write-Log "Output generated in: $OutputDirectory"
    }
}
catch {
    Write-Log "Script failed: $($_.Exception.Message)" -Level "ERROR"
    Write-Log $_.ScriptStackTrace -Level "ERROR"
    exit 1
}
