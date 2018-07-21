param (
    [string]$serverFarmName = $(throw '- serverFarmName is required'),
    [string]$liveInstance = $(throw '-liveInstance is required')
)

Import-Module WebAdministration

# Allow the live instance to finish existing connections without 
# taking any new connections
Write-Host "Taking ($liveInstance) down gracefully"
Set-InstanceState $serverFarmName $liveInstance 1
Write-Host "$liveInstance is draining connections"

$blueGreen = if ($liveInstance -match "blue") {
    "blue"
}
else {
    "green"
}

# Get the name of the live instance
$sitename = Get-ChildItem IIS:\Sites | Select-Object Name | Where-Object {
    $_ -match $blueGreen
}

$sitename = $sitename[0].name

# Keep checking until the live instance is no longer processing requests. We timeout
# after 10s
$startDate = Get-Date
Write-Host "Checking requests per second"
Do {
    $currentConnections = Get-RequestsPerSecond $serverFarmName $liveInstance

    If ($currentConnections -gt 0) {
        Write-Host "Still $currentConnections requests per second"
    }
    else {
        Write-Host "0 requests per second"
    }
} While ($currentConnections -gt 0 -and $startDate.AddSeconds(10) -gt (Get-Date))


# Now that it is finished servicing its requests, we can take it out of the farm
Write-Host "$liveInstance is drained (or we timed out waiting), taking down"
Set-ServerOffline $serverFarmName $liveInstance
Write-Host "Old live site is offline"
