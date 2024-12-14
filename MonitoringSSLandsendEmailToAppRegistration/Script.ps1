param(
    [Parameter(Mandatory = $False, Position = 0, ValueFromPipeline = $false)]
    [System.Int32]
    $minimumCertAgeDays = 90
)

# Embedded JSON data
$RenewalDataJson = @'
[

    { "url": "https://example.com"", "renew_type": "manuel" }
]
'@

# Convert the embedded JSON string into PowerShell objects
$RenewalData = $RenewalDataJson | ConvertFrom-Json

# Prepare an array to hold results
$Results = @()

# SSL variables
$timeoutMilliseconds = 15000
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Net.ServicePointManager]::ServerCertificateValidationCallback = { return $true }

# Loop through each URL in the JSON data
foreach ($entry in $RenewalData) {
    $OutputObject = "" | Select-Object Type, OriginUrl, Name, Hostnames, Gateway, IPAddress, Status, SSLStartDAY, SSLENDDAY, SSENDINDAYS, StatusSSLMinAge, ErrorMessage, RenewalType
    try {
        $Name = $entry.url
        $RenewalType = $entry.renew_type

        # Process DNS information
        $domain = ([System.URI]$Name).Host.Trim()
        $dnsRecord = Resolve-DnsName $domain
        $OutputObject.Name = $($dnsRecord.Name -join ',')
        $OutputObject.OriginUrl = $Name
        $OutputObject.Type = $($dnsRecord.Type -join ',')
        $OutputObject.IPAddress = ($dnsRecord.IPAddress -join ',')
        $OutputObject.Gateway = ''
        $OutputObject.Status = 'OK'
        $OutputObject.ErrorMessage = ''
        $OutputObject.Hostnames = ($dnsRecord.NameHost -join ',')
        $OutputObject.RenewalType = $RenewalType

        # SSL STUFF
        Write-Output "Checking $Name" -ForegroundColor Green
        $req = [Net.HttpWebRequest]::Create($Name)
        $req.Timeout = $timeoutMilliseconds
        $req.AllowAutoRedirect = $true
        try {
            $response = $req.GetResponse() # Ensure the response object is initialized
            if ($response -ne $null) {
                $certExpiresOnString = $req.ServicePoint.Certificate.GetExpirationDateString()
                [datetime]$expiration = [System.DateTime]::Parse($certExpiresOnString)
                [int]$certExpiresIn = ($expiration - (Get-Date)).Days
                $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
                $OutputObject.SSLStartDAY = $certEffectiveDate
                $OutputObject.SSLENDDAY = $expiration
                $OutputObject.SSENDINDAYS = $certExpiresIn

                if ($certExpiresIn -gt $minimumCertAgeDays) {
                    Write-Host "Cert for site $Name expires in $certExpiresIn days [on $expiration]" -ForegroundColor Green
                    $OutputObject.StatusSSLMinAge = 'ok'
                } else {
                    Write-Host "WARNING: Cert for site $Name expires in $certExpiresIn days [on $expiration]" -ForegroundColor Red
                    $OutputObject.StatusSSLMinAge = 'ko'
                }
            } else {
                throw "No valid response from the server for $Name"
            }
        } catch {
            $OutputObject.Status = 'NOT_OK'
            $OutputObject.ErrorMessage = "Exception while checking URL $Name : $_"
            Write-Host "Exception while checking URL $Name : $_" -ForegroundColor Red
        }
        $certExpiresOnString = $req.ServicePoint.Certificate.GetExpirationDateString()
        [datetime]$expiration = [System.DateTime]::Parse($certExpiresOnString)
        [int]$certExpiresIn = ($expiration - (Get-Date)).Days
        $certEffectiveDate = $req.ServicePoint.Certificate.GetEffectiveDateString()
        $OutputObject.SSLStartDAY = $certEffectiveDate
        $OutputObject.SSLENDDAY = $expiration
        $OutputObject.SSENDINDAYS = $certExpiresIn

        if ($certExpiresIn -gt $minimumCertAgeDays) {
            Write-Output "Cert for site $Name expires in $certExpiresIn days [on $expiration]" -ForegroundColor Green
            $OutputObject.StatusSSLMinAge = 'ok'
        } else {
            Write-Output "WARNING: Cert for site $Name expires in $certExpiresIn days [on $expiration]" -ForegroundColor Red
            $OutputObject.StatusSSLMinAge = 'ko'
        }

    } catch {
        $OutputObject.Name = $Name
        $OutputObject.IPAddress = ''
        $OutputObject.Status = 'NOT_OK'
        $OutputObject.ErrorMessage = $_.Exception.Message
        Write-Output "Exception details: $($_.Exception | Format-List | Out-String)" -ForegroundColor Red
        $OutputObject.ErrorMessage = $_.Exception.ToString()
    }

    $Results += $OutputObject
}

# Sort results by SSL end date (ascending)
$Results = $Results | Sort-Object -Property SSLENDDAY

# Export to CSV (optional)
#$Results | Export-Csv C:\user\sslresults.csv -NoTypeInformation

# Modern HTML Style with Column Resizing
$style = @"
<style>
    body { font-family: Arial, sans-serif; margin: 40px; background-color: #f4f4f9; }
    h1 { text-align: center; color: #333; margin-bottom: 40px; }
    table { width: 100%; border-collapse: collapse; margin-bottom: 40px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
    th, td { padding: 12px 15px; text-align: left; vertical-align: top; }
    th { background-color: #0078D7; color: white; font-weight: bold; }
    tr:nth-child(even) { background-color: #f2f2f2; }
    tr:hover { background-color: #f1f1f1; cursor: pointer; }
    td { border-bottom: 1px solid #ddd; word-wrap: break-word; }
    .ssendindays-red { color: red; font-weight: bold; }
    .summary-green { color: green; font-weight: bold; }
    .summary-red { color: red; font-weight: bold; }
    .summary-orange { color: orange; font-weight: bold; }
    footer { text-align: center; margin-top: 20px; font-size: 12px; color: #777; }
</style>
"@

# Generate modern HTML with dynamic resizing
#$HtmlOutputPath = ""

# Prepare the HTML header and table structure
$HtmlContent = @"
<html>
<head>
$style
</head>
<body>
<h1>SSL Certificate Report</h1>
<p class="summary-green">Total links analyzed: $($Results.Count)</p>
<p class="summary-red">Total that will expire in less than 90 days: $([math]::Max(0, ($Results | Where-Object { $_.StatusSSLMinAge -eq 'ko' }).Count))</p>
<p class="summary-orange">Total that I cannot reach: $([math]::Max(0, ($Results | Where-Object { $_.Status -eq 'NOT_OK' }).Count))</p>
<table class="table table-sm">
    <thead>
        <tr>
            <th>Type</th>
            <th>Origin URL</th>
            <th>Name</th>
            <th>Hostnames</th>
            <th>Gateway</th>
            <th>IP Address</th>
            <th>Status</th>
            <th>SSL Start Date</th>
            <th>SSL End Date</th>
            <th>Days Until Expiration</th>
            <th>Status SSL Min Age</th>
            <th>Renewal Type</th>
        </tr>
    </thead>
    <tbody>
"@

# Populate the table rows with data
foreach ($result in $Results) {
    $ssendInDaysClass = if ($result.SSENDINDAYS -lt 90) { "ssendindays-red" } else { "" }
    
    # Replace commas with line breaks for better formatting
    $name = $result.Name -replace ',', '<br>'
    $ipAddress = $result.IPAddress -replace ',', '<br>'

    $HtmlContent += "<tr>"
    $HtmlContent += "<td>$($result.Type)</td>"
    $HtmlContent += "<td>$($result.OriginUrl)</td>"
    $HtmlContent += "<td>$name</td>"   # Use the formatted Name
    $HtmlContent += "<td>$($result.Hostnames)</td>"
    $HtmlContent += "<td>$($result.Gateway)</td>"
    $HtmlContent += "<td class=''>$ipAddress</td>"   # Use the formatted IP Address
    $HtmlContent += "<td>$($result.Status)</td>"
    $HtmlContent += "<td>$($result.SSLStartDAY)</td>"
    $HtmlContent += "<td>$($result.SSLENDDAY)</td>"
    $HtmlContent += "<td class='$ssendInDaysClass'>$($result.SSENDINDAYS)</td>"
    $HtmlContent += "<td>$($result.StatusSSLMinAge)</td>"
    $HtmlContent += "<td>$($result.RenewalType)</td>"
    $HtmlContent += "</tr>"
}

# Close the table and body
$HtmlContent += @"
    </tbody>
</table>
<footer>Generated on $(Get-Date)</footer>
</body>
</html>
"@


# Prepare data for Logic App
$totalLinksAnalyzed = $Results.Count
$totalExpiringSoon = ($Results | Where-Object { $_.StatusSSLMinAge -eq 'ko' }).Count
$totalNotReachable = ($Results | Where-Object { $_.Status -eq 'NOT_OK' }).Count
# Logic App URL
$logicAppUrl = ""
# Create body for POST request
$body = @{
    "Total links analyzed" = $totalLinksAnalyzed
    "Total that will expire in less than 90 days" = $totalExpiringSoon
    "Total that I cannot reach" = $totalNotReachable
    "html" = $htmlContent
} | ConvertTo-Json -Depth 5



# Send the payload to the Logic App
try {
    Invoke-RestMethod -Uri $logicAppUrl -Method Post -Body $body -ContentType 'application/json'
    Write-Output "Data sent to Logic App successfully!" -ForegroundColor Green
} catch {
    $OutputObject.Name = $Name
    $OutputObject.IPAddress = ''
    $OutputObject.Status = 'NOT_OK'
    $OutputObject.ErrorMessage = "DNS or general failure for $Name : $_"
    Write-Host "Failed to process $Name due to: $_" -ForegroundColor Red
}
