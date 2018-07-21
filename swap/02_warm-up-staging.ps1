param (
    [String]$instanceToWarm = $(throw '-instanceToWarm is required'),
    [String]$bluePort = $(throw "-bluePort is required"),
    [String]$greenPort = $(throw "-greenPort is required"),
    [string]$serverFarmName = $(throw '- serverFarmName is required'),
    [string]$warmUpPath = $("")
)

# We keep making requests until the response time is less than 400ms
$minTime = 400

# Determine the port of the instance we want to warm up
$port = if ($instanceToWarm -match "blue") {
    $bluePort
}
else {
    $greenPort
}

# The path we'll use to warm the instance up
$stagingSite = "http://${serverFarmName}:${port}/${warmUpPath}"
Write-Host "Warming $instanceToWarm up on $stagingSite"

# Loop until we have a satisfactory response time
Do {
    $time = Measure-Command {
        $res = Invoke-WebRequest $stagingSite
    }
    $ms = $time.TotalMilliSeconds
    If ($ms -ge $minTime) {
        Write-Host "$($res.StatusCode) from $stagingSite in $($ms)ms"
    }
} While ($ms -ge $minTime)
Write-Host "$($res.StatusCode) from $stagingSite in $($ms)ms"


