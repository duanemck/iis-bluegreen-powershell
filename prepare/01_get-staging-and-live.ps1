param (
    [string]$serverFarmName = $(throw '-serverFarmName is required'),
    [String]$bluePath = $(throw '-bluePath is required'),
    [String]$greenPath = $(throw '-greenPath is required')
)

Write-Host "Detecting live vs staging:"

$result = @{}

if (Get-ServerOnline $serverFarmName "$serverFarmName-blue") {
    Write-Host "`tLive is Blue"
    Write-Host "`tStaging is Green"
    Write-Host "------------------"

    $result["LiveBlueGreen"] = "Blue"
    $result["LiveDeployPath"] = $bluePath
    $result["LiveServer"] = "$serverFarmName-blue"

    $result["StagingBlueGreen"] = "Green"
    $result["StagingDeployPath"] = $greenPath
    $result["StagingServer"] = "$serverFarmName-green"
}
else {
    Write-Host "`tLive is Green"
    Write-Host "`tStaging is Blue"
    Write-Host "------------------"

    $result["LiveBlueGreen"] = "Green"
    $result["LiveDeployPath"] = $greenPath
    $result["LiveServer"] = "$serverFarmName-green"

    $result["StagingBlueGreen"] = "Blue"
    $result["StagingDeployPath"] = $bluePath
    $result["StagingServer"] = "$serverFarmName-blue"
}

return $result