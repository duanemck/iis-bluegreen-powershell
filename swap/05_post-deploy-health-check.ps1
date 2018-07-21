param (
    [string]$serverFarmName = $(throw "-serverFarmName is required"),
    [string]$oldStagingSite = $(throw "-oldStagingSite is required"),
    [string]$oldLiveSite = $(throw "-oldLiveSite is required")
)

$webFarm = Get-ServerFarm $serverFarmName
$servers = $webFarm.GetCollection()

# Iterate over each instance an ensure it is now in the expected state
$servers | ForEach-Object {
    $nodeName = $_.GetAttribute('address').Value
    $wasStaging = $nodeName -eq $oldStagingSite
    $wasLive = $nodeName -eq $oldLiveSite

    # Read the IIS counters
    $arr = $_.GetChildElement("applicationRequestRouting")
    $counters = $arr.GetChildElement("counters")
    $isHealthy = $counters.GetAttributeValue("isHealthy")
    $state = $counters.GetAttributeValue("state")
    $requests = $counters.GetAttributeValue("requestPerSecond")

    $isAvailable = $state -eq 0
    $isEnabled = $_.GetAttribute('enabled').Value

    $role = if ($wasStaging) {
        "Live"
    }
    else {
        "Staging"
    }

    # Log for debugging purposes
    Write-Host "======================================"
    Write-Host "$nodeName ($role)"
    Write-Host "--------------------------------------"
    Write-Host "Is available`t`t`t:`t $isAvailable"
    Write-Host "Is healthy`t`t`t:`t $isHealthy"
    Write-Host "Is online`t`t`t:`t $isEnabled"
    Write-Host "Requests per second`t`t:`t $requests"


    $isError = 0
    #Was staging, should now be live
    if ($wasStaging) {
        if (-not $isHealthy) {
            Write-Error "New live node is not healthy!"
            $isError = 1
        }
        if (-not $isAvailable) {
            Write-Error "New live node is not available!"
            $isError = 1
        }
        if (-not $isEnabled) {
            Write-Error "New live node is not online!"
            $isError = 1
        }
    }

    #Was live, should now be staging
    if ($wasLive) {
        if ($isEnabled) {
            Write-Error "New staging node is online, should not be!"
            $isError = 1
        }
    }
    Write-Host ""
    # If error, fail the script to notify the release tool that something is wrong
    if ($isError -eq 1) {
        Write-Error "!!Node is NOT in the expected state"
        exit 1
    }
    else {
        Write-Host "Node is in the expected state"
    }


}
Write-Host "======================================"

