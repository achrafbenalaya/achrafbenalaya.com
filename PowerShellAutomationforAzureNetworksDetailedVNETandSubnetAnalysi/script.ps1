#Connect-AzAccount
# Define the subscription name
$subs = Get-AzSubscription 
# Initialize an array to store the results
$results = @()
# Initialize location  to store the results
$csvFilePath = "insert your path here\data.csv"
foreach ($Sub in $subs) {
    Write-Host "***************************"
    Write-Host " "
    Write-Host "Subscription: $Sub"
    Write-Host " "
    Write-Host "***************************"
    Write-Host " "
    $Sub.Name 
    
    $SelectSub = Select-AzSubscription -SubscriptionName $Sub.Name


    # Get all virtual networks in the subscription
    $VNETs = Get-AzVirtualNetwork
    foreach ($VNET in $VNETs) {
        Write-Host "--------------------------"
        Write-Host " "
        Write-Host "   vNet: $($VNET.Name)"
        Write-Host "   AddressPrefixes: $($VNET.AddressSpace.AddressPrefixes -join ', ')"
        Write-Host " "

        # Get expanded virtual network details including subnets and IP configurations
        $vNetExpanded = Get-AzVirtualNetwork -Name $VNET.Name -ResourceGroupName $VNET.ResourceGroupName -ExpandResource 'subnets/ipConfigurations'

        foreach ($subnet in $vNetExpanded.Subnets) {
            Write-Host "       Subnet: $($subnet.Name)"
            $connectedDevices = $subnet.IpConfigurations.Count
            Write-Host "          Connected devices: $connectedDevices"

            # Calculate total, used, and available IPs in the subnet
            $subnetMask = $subnet.AddressPrefix.Split('/')[1]
            $totalIps = [math]::Pow(2, 32 - $subnetMask)
            $reservedIps = 5  # 5 IPs are reserved by Azure
            $usedIps = $connectedDevices + $reservedIps
            $availableIps = $totalIps - $usedIps
            Write-Host "          Total IPs: $totalIps"
            Write-Host "          Used IPs: $usedIps"
            Write-Host "          Available IPs: $availableIps"

            # Get activated Service Endpoints
            $serviceEndpoints = if ($subnet.ServiceEndpoints) { $subnet.ServiceEndpoints.Service -join ', ' } else { "None" }
            Write-Host "          Service Endpoints: $serviceEndpoints"

            # Get Delegations Service Names
            $delegations = if ($subnet.Delegations) { $subnet.Delegations.ServiceName -join ', ' } else { "None" }
            Write-Host "          Delegations: $delegations"

            # Join the address prefixes into a single string
            $addressPrefixString = $subnet.AddressPrefix -join ', '

            # Add information for each IP configuration in the subnet
            foreach ($ipConfig in $subnet.IpConfigurations) {
                Write-Host "            IP Address: $($ipConfig.PrivateIpAddress)"

                # Attempt to get the VM name associated with this IP configuration
                $nic = Get-AzNetworkInterface | Where-Object { $_.IpConfigurations.Id -eq $ipConfig.Id }
                if ($nic) {
                    $vm = Get-AzVM | Where-Object { $_.Id -eq $nic.VirtualMachine.Id }
                    $vmName = if ($vm) { $vm.Name } else { "Not Available" }

                    # Add the information to the results array
                    $results += [PSCustomObject]@{
                        Subscription      = $Sub
                        VNet              = $VNET.Name
                        Subnet            = $subnet.Name
                        AddressPrefix     = $addressPrefixString
                        TotalIps          = $totalIps
                        UsedIps           = $usedIps
                        AvailableIps      = $availableIps
                        ConnectedDevices  = $connectedDevices
                        ServiceEndpoints  = $serviceEndpoints
                        Delegations       = $delegations
                        IpAddress         = $ipConfig.PrivateIpAddress
                        VMName            = $vmName
                        NicName           = $nic.Name
                    }
                } else {
                    # Add the information to the results array
                    $results += [PSCustomObject]@{
                        Subscription      = $Sub
                        VNet              = $VNET.Name
                        Subnet            = $subnet.Name
                        AddressPrefix     = $addressPrefixString
                        TotalIps          = $totalIps
                        UsedIps           = $usedIps
                        AvailableIps      = $availableIps
                        ConnectedDevices  = $connectedDevices
                        ServiceEndpoints  = $serviceEndpoints
                        Delegations       = $delegations
                        IpAddress         = $ipConfig.PrivateIpAddress
                        VMName            = "Not Available"
                        NicName           = "Not Available"
                    }
                }
            }

            # If there are no IP configurations, add a record with "0" connected devices
            if ($connectedDevices -eq 0) {
                $results += [PSCustomObject]@{
                    Subscription      = $Sub
                    VNet              = $VNET.Name
                    Subnet            = $subnet.Name
                    AddressPrefix     = $addressPrefixString
                    TotalIps          = $totalIps
                    UsedIps           = $usedIps
                    AvailableIps      = $availableIps
                    ConnectedDevices  = 0
                    ServiceEndpoints  = $serviceEndpoints
                    Delegations       = $delegations
                    IpAddress         = ""
                    VMName            = ""
                    NicName           = ""
                }
            }

            Write-Host " "
        }
    }
    Write-Host "***************************"
}

# Display the results in a table format
$results | Format-Table -AutoSize

# Export the results to a CSV file

$results | Export-Csv -Path $csvFilePath -NoTypeInformation

# Output a message to indicate the script has finished
Write-Output "Script completed. Results have been saved to CSV files."

# Open the CSV file to show the results
Invoke-Item -Path $csvFilePath