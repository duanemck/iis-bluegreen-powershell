param (
    [string]$machines = $(throw '-machines is required'),
    [string]$username = $(throw '-username is required'),
    [string]$password = $(throw '-password is required'),
    [string]$serverFarmName = $(throw '-serverFarmName is required'),
    [String]$bluePath = $(throw '-bluePath is required'),
    [String]$greenPath = $(throw '-greenPath is required'),
    [String]$bluePort = $(throw '-bluePort is required'),
    [String]$greenPort = $(throw '-greenPort is required'),
    [String]$warmUpPath = $(throw '-warmUpPath is required'),
)

Import-Module -Force "$PSScriptRoot\lib\server-farm.psm1"
Import-Module -Force "$PSScriptRoot\lib\remote-execution.psm1"

$credential = Get-ServerCredentials $username $password
$remoteMachines = $machines -split ","

$remoteMachines | ForEach-Object {
    Write-Host "========================================================================================"
    Write-Host "Opening remote session to $_"
    $session = New-PsSession -ComputerName $_ -Credential $credential
    Import-ModuleRemotely "server-farm" $session
    $currentConfig = Invoke-ScriptRemotely -localScriptFile ".\prepare\01_get-staging-and-live.ps1" -Session $session -ArgumentList $serverFarmName, $bluePath, $greenPath

    Write-Host "Current Blue/Green Config:"
    $currentConfig
    Write-Host "-----------------------------"

    Exit-PSSession
    Write-Host "Session Closed"
    Write-Host "========================================================================================"
}

$deployPath = $currentConfig["LiveDeployPath"]
$liveServer = $currentConfig["LiveServer"]
$stagingServer = $currentConfig["StagingServer"]

$remoteMachines | ForEach-Object {

    # INSERT YOUR CODE HERE TO DEPLOY TO $deployPath on each machine

}

$remoteMachines | ForEach-Object {
    Write-Host "========================================================================================"
    Write-Host "Opening remote session to $_"
    $session = New-PsSession -ComputerName $_ -Credential $credential
    Import-ModuleRemotely "server-farm" $session

    Invoke-ScriptRemotely -localScriptFile ".\swap\02_warm-up-staging.ps1" -Session $session -ArgumentList $stagingServer, $bluePort, $greenPort, $serverFarmName, $warmUpPath
    Invoke-ScriptRemotely -localScriptFile ".\swap\03_bring-staging-up.ps1" -Session $session -ArgumentList $serverFarmName, $stagingServer
    Invoke-ScriptRemotely -localScriptFile ".\swap\04_drain-live-instance.ps1" -Session $session -ArgumentList $serverFarmName, $liveServer
    Invoke-ScriptRemotely -localScriptFile ".\swap\05_post-deploy-health-check.ps1" -Session $session -ArgumentList $serverFarmName, $stagingServer, $liveServer

    Exit-PSSession
    Write-Host "Session Closed"
    Write-Host "========================================================================================"
}

Write-Host "Deployment complete"