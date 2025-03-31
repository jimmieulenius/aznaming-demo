param (
    [String]
    $AppName = "myproject",

    [Parameter(Mandatory = $true)]
    [String]
    $Environment,

    [String]
    $Location = "GermanyWestCentral",

    [Parameter(Mandatory = $true)]
    [Int]
    $Id
)

$toolsPath = "$PSScriptRoot/../tools"

If ($IsWindows) {
    $toolsPath = "$toolsPath/win"
}
elseif ($IsLinux) {
    $toolsPath = "$toolsPath/linux"
}

$Env:PATH += "$([System.IO.Path]::PathSeparator)$toolsPath"

$values = @(
    "workload=$AppName",
    "environment=$Environment",

    "location=$Location"
)

if ($Id -gt 0) {
    $values += "instance=$Id"
}

$configPath = "$PSScriptRoot/../config/aznaming/config.json"

# Using explicit template
$resourceName = aznamingcli name `
    --template '{ENVIRONMENT}[{SEPARATOR}]{WORKLOAD}[{SEPARATOR}{INSTANCE}][{SEPARATOR}]{RESOURCE_TYPE}' `
    --values ($values + @(
        "RESOURCE_TYPE=Resources/resourcegroups"
        'SEPARATOR=-'
    ))

$resourceName `
    | Out-Default

# Using static value in template
$resourceName = aznamingcli name `
    --template 'nip-{ENVIRONMENT}[{-}]{WORKLOAD}[{-}{INSTANCE}][{-}]{RESOURCE_TYPE}' `
    --values ($values + @(
        "RESOURCE_TYPE=Resources/resourcegroups"
        'SEPARATOR=-'
    ))

$resourceName `
    | Out-Default

# Using resource type as template
$resourceName = aznamingcli name `
    --template 'Resources/resourcegroups' `
    --values $values

$resourceName `
    | Out-Default

# Using resource type as template to enforce format restrictions on specific resource type
$resourceName = aznamingcli name `
    --template 'Storage/storageAccounts' `
    --values $values

$resourceName `
    | Out-Default

# Using abbreviation of resource type as template
$resourceName = aznamingcli name `
    --template 'st' `
    --values $values

$resourceName `
    | Out-Default

$values = @(
    "app_name=$AppName",
    "environment=$Environment",

    "location=$Location"
)

if ($Id -gt 0) {
    $values += "id=$Id"
}

# Using configuration file to define template
$resourceGroupName = aznamingcli name `
    --template 'rg' `
    --values $values `
    --config-uri $configPath

$resourceGroupName `
| Out-Default

# Using optional components in template
$resourceName = aznamingcli name `
    --template 'st' `
    --values (
        $values + @(
            "PURPOSE=SFTP"
        )
     ) `
    --config-uri $configPath

$resourceName `
| Out-Default

# Using invalid values will result validation failure for that resource type
$resourceName = aznamingcli name `
    --template 'st' `
    --values (
        $values + @(
            "PURPOSE=sftp-2"
        )
     ) `
    --config-uri $configPath

$resourceName `
| Out-Default

# Check unique name
$resourceName = aznamingcli name `
    --template 'KeyVault/vaults' `
    --values $values `
    --check-unique-name `
    --subscription-id $subscriptionId `
    --config-uri $configPath

$resourceName `
| Out-Default

# Check unique name and within our resource group 
$resourceName = aznamingcli name `
    --template 'KeyVault/vaults' `
    --values $values `
    --check-unique-name `
    --subscription-id $subscriptionId `
    --resource-group-name $resourceGroupName `
    --config-uri $configPath

$resourceName `
| Out-Default

# Using custom abbreviation in config
$resourceName = aznamingcli name `
    --template 'managedIdentity/userAssignedIdentities' `
    --values $values `
    --config-uri $configPath

$resourceName `
    | Out-Default

# Using non-existing abbreviation of resource type as template
$resourceName = aznamingcli name `
    --template 'mi' `
    --values $values

$resourceName `
    | Out-Default

# Using alias on template
$resourceName = aznamingcli name `
    --template 'mi' `
    --values $values `
    --config-uri $configPath

$resourceName `
    | Out-Default

# Generate JSON object with names using local config file
$resourceNameJson = aznamingcli name `
    --graph "$PSScriptRoot/../config/aznaming/graph.json" `
    --values $values `
    --config-uri $configPath

$resourceNameJson `
    | Out-Default

# Generate JSON object with names using config from URL
$resourceNameJson = aznamingcli name `
    --graph "$PSScriptRoot/../config/aznaming/graph.json" `
    --values $values `
    --config-uri 'https://raw.githubusercontent.com/jimmieulenius/aznaming-demo/refs/heads/main/config/aznaming/config-web.json'

$resourceNameJson `
    | Out-Default