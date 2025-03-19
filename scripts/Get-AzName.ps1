param (
    [String]
    $BusinessUnit = "mybusinessunit",

    [String]
    $Project = "myproject",

    [String]
    $Environment = "dev",

    [Int]
    $Instance = 0
)

$toolsPath = "$PSScriptRoot/../tools"
$extension = $null

If ($IsWindows) {
    $toolsPath = "$toolsPath/win"
    $extension = ".exe"
}

$azNamingPath = "$toolsPath/aznamingcli$extension"

$values = @(
    "business_unit=$BusinessUnit",
    "project=$Project",
    "environment=$Environment"
)

if ($Instance -gt 0) {
    $values += "instance=$Instance"
}

$configPath = "$PSScriptRoot/../config/aznaming/config.json"

$resourceGroupName = & $azNamingPath name `
    --template 'Resources/resourcegroups' `
    --values $values `
    --config-uri $configPath

$resourceGroupName `
| Out-Default

$resourceNameJson = & $azNamingPath name `
    --graph "$PSScriptRoot/../config/aznaming/graph.json" `
    --values $values `
    --location 'westeurope' `
    --config-uri $configPath

# $resourceNameJson = & $azNamingPath name `
#     --graph "$PSScriptRoot/config/aznaming/graph.json" `
#     --values $values `
#     --check-unique-name `
#     --subscription-id $subscriptionId `
#     --resource-group-name $resourceGroupName `
#     --location 'germanywestcentral' `
#     --config-uri $configPath

$resourceNameJson `
| Out-Default