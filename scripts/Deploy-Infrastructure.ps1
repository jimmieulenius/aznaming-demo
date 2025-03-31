param (
    [String]
    $BusinessUnit = $Env:BUSINESS_UNIT ?? "myBusinessUnit",

    [String]
    $Project = $Env:PROJECT ?? "myProject",

    [Parameter(Mandatory = $true)]
    [ValidateSet(
        'Dev', 
        'Qas',
        'Run'
    )]
    [String]
    $Environment,

    [Parameter(Mandatory = $true)]
    [ValidateRange(0, 99)]
    [Int]
    $Instance,

    [Parameter(Mandatory = $true)]
    [String]
    [ValidateSet(
        'Plan', 
        'Apply',
        'Destroy'
    )]
    $Action,

    [Switch]
    $Initialize,

    [Switch]
    $Force
)

function New-AzRoleAssignmentIfNotExist {
    param (
        [String]
        $RoleDefinitionName,

        [String]
        $ApplicationId,

        [String]
        $Scope
    )

    $roleAssignmentObject = Get-AzRoleAssignment `
        -ServicePrincipalName $ApplicationId `
        -Scope $Scope

    if (-not $roleAssignmentObject) {
        $roleAssignmentObject = New-AzRoleAssignment `
            -RoleDefinitionName $RoleDefinitionName `
            -ApplicationId $ApplicationId `
            -Scope $Scope
    }

    return $roleAssignmentObject
}

$currentErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Stop'

try {
    if (
        (-not $Force) `
        -and (-not $PSBoundParameters.ContainsKey('Initialize'))
    ) {
        [Bool] $Initialize = (
            & {
                function Get-Value {
                    param (
                        [ValidateSet(
                            'y',
                            'n',
                            ''
                        )]
                        [String]
                        $Initialize
                    )

                    return ($Initialize -ieq 'y')
                }

                try {
                    return Get-Value `
                        -Initialize ((Read-Host 'Initialize (Y/N)') ?? '')
                }
                catch {
                    throw $_
                }
            }
        )
    }

    $tfBaseWorkingDirectory = "$PSScriptRoot/../terraform/"
    $tfWorkingDirectory = "$tfBaseWorkingDirectory/.terraform"
    $currentLocation = (Get-Location).Path

    Set-Location $tfBaseWorkingDirectory

    $toolsPath = "$PSScriptRoot/../tools"

    If ($IsWindows) {
        $toolsPath = "$toolsPath/win"
    }
    elseif ($IsLinux) {
        $toolsPath = "$toolsPath/linux"
    }

    $Env:PATH += "$([System.IO.Path]::PathSeparator)$toolsPath"

    $values = @(
        "business_unit=$BusinessUnit",
        "project=$Project",
        "environment=$Environment"
    )

    if ($Instance -gt 0) {
        $values += "instance=$Instance"
    }

    $varsPathFormatString = "$tfBaseWorkingDirectory/main.vars{0}.json"
    $varsPath = $varsPathFormatString -f $null
    $varsObject = (
        Get-Content `
            -Path $varsPath `
            -Raw
    ) `
    | ConvertFrom-Json `
        -AsHashtable

    $varsEnvironmentPath = $varsPathFormatString -f ".$($Environment.ToLower())"
    $varsEnvironmentObject = (
        Get-Content `
            -Path $varsEnvironmentPath `
            -Raw
    ) `
    | ConvertFrom-Json `
        -AsHashtable
    $subscriptionId = $varsEnvironmentObject.subscription_id

    Set-AzContext `
        -SubscriptionId $subscriptionId

    $configDirectory = "$PSScriptRoot/../config"

    $resourceGroupName = aznamingcli name `
        --template 'Resources/resourcegroups' `
        --values $values `
        --config-uri `
            "$configDirectory/aznaming/config.json"

    $resourceNameJson = aznamingcli name `
        --graph "$configDirectory/aznaming/graph.json" `
        --values $values `
        --check-unique-name `
        --subscription-id $subscriptionId `
        --resource-group-name $resourceGroupName `
        --location 'germanywestcentral' `
        --config-uri `
            "$configDirectory/aznaming/config.json"

    $resourceNameObject = $resourceNameJson `
    | ConvertFrom-Json `
        -AsHashtable

    $resourceNameJson

    if ($Initialize) {
        $resourceGroupObject = New-AzResourceGroup `
            -Name $resourceGroupName `
            -Location $varsObject.location `
            -Force

        $resourceGroupObject

        $identity = New-AzUserAssignedIdentity `
            -Name $resourceNameObject.user_identity `
            -ResourceGroupName $resourceGroupName `
            -Location $varsObject.location

        $identity

        $servicePrincipalObject = $null

        do {
            Start-Sleep `
                -Seconds 5

            $servicePrincipalObject = Get-AzADServicePrincipal `
                -ApplicationId $identity.ClientId
        }
        while (-not $servicePrincipalObject)

        New-AzRoleAssignmentIfNotExist `
            -RoleDefinitionName "Owner" `
            -ApplicationId $identity.ClientId `
            -Scope $resourceGroupObject.ResourceId
    }

    Remove-Item `
        -Path $tfWorkingDirectory `
        -Recurse `
        -Force `
        -ErrorAction 'SilentlyContinue'

    $target = "$($Environment.ToLower())$(($Instance -gt 0) ? "_$Instance" : $null)"
    $plan = "$tfBaseWorkingDirectory/tfplan.$target"

    terraform init

    terraform validate

    if ($Action -ieq 'Plan') {
        terraform plan `
            -var-file="$($varsPath -f $null)" `
            -var-file="$varsEnvironmentPath" `
            -var="resource_names_json=$resourceNameJson" `
            -out="$plan"
    }
    elseif ($Action -ieq 'Apply') {
        terraform apply $plan
    }
    elseif ($Action -ieq 'Destroy') {
        terraform destroy `
            -var-file="$($varsPath -f $null)" `
            -var-file="$varsEnvironmentPath" `
            -var="resource_names_json=$resourceNameJson"
    }
}
finally {
    $ErrorActionPreference = $currentErrorActionPreference

    Set-Location $currentLocation
}
