param (
    [string]$serverFarmName = $(throw '-serverFarmName is required'),
    [string]$stagingInstance = $(throw '-stagingInstance is required')
)

# Make sure it is set to state=Available
Set-InstanceState $serverFarmName $stagingInstance 0
# Bring it online
Set-ServerOnline $serverFarmName $stagingInstance

Write-Host "Staging brought up"
