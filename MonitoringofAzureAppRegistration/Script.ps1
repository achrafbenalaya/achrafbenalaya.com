

# Define the Application (Client) ID and Secret

$ApplicationClientIddata = Get-AutomationPSCredential -Name 'ApplicationClientId'
$ApplicationClientSecretdata = Get-AutomationPSCredential -Name 'ApplicationClientSecret'
$TenantIddata = Get-AutomationPSCredential -Name 'TenantId'

# Convert the secure strings to plain text
$ApplicationClientId = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApplicationClientIddata.Password)
)
$ApplicationClientSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ApplicationClientSecretdata.Password)
)
$TenantId = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($TenantIddata.Password)
)

# Log the results
# Write-Host "Application Client ID: $ApplicationClientId"
# Write-Host "Application Client Secret: $ApplicationClientSecret"
# Write-Host "Tenant ID: $TenantId"


# Convert the Client Secret to a Secure String
$SecureClientSecret = ConvertTo-SecureString -String $ApplicationClientSecret -AsPlainText -Force

# Create a PSCredential Object Using the Client ID and Secure Client Secret
$ClientSecretCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $ApplicationClientId, $SecureClientSecret

# Connect to Microsoft Graph using app-only authentication
try {
    Connect-MgGraph -TenantId $TenantId -ClientSecretCredential $ClientSecretCredential 
    Write-Output "Connected to Microsoft Graph successfully." -ForegroundColor Green
} catch {
    Write-Output "Failed to connect to Microsoft Graph: $_" -ForegroundColor Red
    exit
}

# Retrieve all applications
try {
    $Applications = Get-MgApplication -All
} catch {
    Write-Output "Failed to retrieve applications: $_" -ForegroundColor Red
    exit
}

# Start building the HTML content with the summary at the beginning
$HtmlContent = @"
<html>
<head>
    <style>
        table {
            font-family: Arial, sans-serif;
            border-collapse: collapse;
            width: 100%;
        }
        th, td {
            border: 1px solid #dddddd;
            text-align: left;
            padding: 8px;
        }
        tr:nth-child(even) {
            background-color: #f2f2f2;
        }
        th {
            background-color: #4CAF50;
            color: white;
        }
        .expired {
            color: red;
            font-weight: bold;
        }
        .expiring {
            color: blue;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <h2>Application Secret Expiration Report</h2>
"@

$Now = Get-Date
$ApplicationSecretDetails = @()

$ExpiredCount = 0
$ExpiringCount = 0
$ExpiredWithNoActiveCount = 0  # Counter for expired apps with no active secrets

foreach ($App in $Applications) {
    $AppName = $App.DisplayName
    $AppID   = $App.AppId

    # Get credentials for the application
    $AppCreds = Get-MgApplication -ApplicationId $App.Id |
        Select-Object PasswordCredentials

    $Secrets = $AppCreds.PasswordCredentials
    $TotalSecretsCount = $Secrets.Count
    $ActiveSecretsCount = 0

    foreach ($Secret in $Secrets) {
        $EndDate = $Secret.EndDateTime
        $RemainingDaysCount = ($EndDate - $Now).Days

        # Get owners for the application
        $Owners = Get-MgApplicationOwner -ApplicationId $App.Id
        $OwnerName = ""

        # Check if any owners exist and set the OwnerName
        if ($Owners) {
            if ($Owners.Count -gt 0) {
                $OwnerNames = @()
                foreach ($Owner in $Owners) {
                    if ($Owner.AdditionalProperties.userPrincipalName) {
                        $OwnerNames += $Owner.AdditionalProperties.userPrincipalName
                    } elseif ($Owner.AdditionalProperties.displayName) {
                        $OwnerNames += $Owner.AdditionalProperties.displayName + ' (Application)'
                    }
                }
                $OwnerName = ($OwnerNames -join ", ") # Join multiple owner names with a comma
            } else {
                $OwnerName = '<<No Owner>>'
            }
        }

        # Count active secrets
        if ($RemainingDaysCount -ge 0) {
            $ActiveSecretsCount++
        }

        # Check expiration status and categorize
        if ($RemainingDaysCount -lt 0) {
            $ExpiredCount++
            if ($ActiveSecretsCount -eq 0) {
                $ExpiredWithNoActiveCount++  # Increment if there are no active secrets
            }
            $ApplicationSecretDetails += [pscustomobject]@{
                AppName = $AppName
                AppID = $AppID
                EndDate = $EndDate
                RemainingDaysCount = $RemainingDaysCount
                OwnerName = $OwnerName
                TotalSecretsCount = $TotalSecretsCount
                ActiveSecretsCount = $ActiveSecretsCount
            }
        } elseif ($RemainingDaysCount -le 90) {
            $ExpiringCount++
            $ApplicationSecretDetails += [pscustomobject]@{
                AppName = $AppName
                AppID = $AppID
                EndDate = $EndDate
                RemainingDaysCount = $RemainingDaysCount
                OwnerName = $OwnerName
                TotalSecretsCount = $TotalSecretsCount
                ActiveSecretsCount = $ActiveSecretsCount
            }
        }
    }
}

# Sort by expiration, expired first, followed by those expiring soon
$SortedApplicationSecretDetails = $ApplicationSecretDetails | Sort-Object -Property RemainingDaysCount

# Add the summary to the top of the HTML content
$TotalApplicationsCount = $Applications.Count

$HtmlContent += @"
    <h3>Summary</h3>
    <p>Apps Expired: <span style="font-size: 24px; font-weight: bold;"> $ExpiredCount</span></p>
    <p>Apps About to Expire: <span style="font-size: 24px; font-weight: bold;"> $ExpiringCount</span></p>
    <p>Total Apps Expired and About to Expire: <span style="font-size: 24px; font-weight: bold;"> $( $ExpiredCount + $ExpiringCount )</span></p>
    <p>Total App Registrations in Active Directory: <span style="font-size: 24px; font-weight: bold;"> $TotalApplicationsCount</span></p>
    <p>Expired Apps with No Active Secrets: <span style="font-size: 24px; font-weight: bold;"> $ExpiredWithNoActiveCount</span></p>

    <table>
        <tr>
            <th>#</th>
            <th>Application Name</th>
            <th>Application ID</th>
            <th>Secret End Date</th>
            <th>Owner</th>
            <th>Expired (Days Left)</th>
            <th>Total Number of Secrets</th>
            <th>Active Secrets</th>
        </tr>
"@

$rowNumber = 1  # Initialize row number counter
foreach ($AppDetails in $SortedApplicationSecretDetails) {
    # Determine display for remaining days left
    if ($AppDetails.RemainingDaysCount -lt 0) {
        $DaysLeftDisplay = "<span class='expired'>Expired</span>"
    } else {
        $DaysLeftDisplay = "<span class='expiring'>$($AppDetails.RemainingDaysCount) days left</span>"
    }

    # Build the HTML table row
    $HtmlContent += @"
    <tr>
        <td>$rowNumber</td>
        <td>$($AppDetails.AppName)</td>
        <td>$($AppDetails.AppID)</td>
        <td>$($AppDetails.EndDate.ToString("yyyy-MM-dd"))</td>
        <td>$($AppDetails.OwnerName)</td>
        <td>$DaysLeftDisplay</td>
        <td>$($AppDetails.TotalSecretsCount)</td>
        <td>$($AppDetails.ActiveSecretsCount)</td>
    </tr>
"@
    $rowNumber++  # Increment row number counter
}

# Close the HTML content
$HtmlContent += @"
    </table>
</body>
</html>
"@

# Convert the HTML content to JSON
$JsonPayload = @{
    HtmlContent = $HtmlContent
} | ConvertTo-Json -Depth 3

# Define Logic App URL
$LogicAppUrl = ""

# Send JSON to Logic App
try {
    $Response = Invoke-RestMethod -Uri $LogicAppUrl -Method Post -Body $JsonPayload -ContentType 'application/json'
    Write-Output "HTML content successfully sent to Logic App." -ForegroundColor Green
} catch {
    Write-Output "Failed to send HTML content to Logic App: $_" -ForegroundColor Red
}
