# Azure Virtual Network and Subnet Analysis Script

This PowerShell script is designed to automate the process of retrieving detailed information about virtual networks (VNETs) and their subnets within an Azure subscription. It performs the following tasks:

1. **Azure Subscription Connection**: Connects to your Azure account and retrieves all available subscriptions.

2. **Subscription Iteration**: Iterates through each subscription to gather VNET information.

3. **Virtual Network Retrieval**: For each subscription, retrieves all virtual networks.

4. **Detailed VNET Information**: For each virtual network, retrieves detailed information including subnets and IP configurations.

5. **Result Compilation**: Compiles the results into an array of objects containing details like VNET name, address prefixes, subnets, and IP configurations.

6. **CSV Export**: Exports the compiled results to a CSV file at the specified path.

## Usage

To run the script, execute the following command in PowerShell:

./script.ps1