$ErrorActionPreference = "Stop"
# Get the server farm object based on the name and optional server configuration file
function Get-ServerFarm([string]$serverFarmName, [string]$applicationHostConfig = $("$env:systemroot\system32\inetsrv\config\applicationhost.config")) {
    [System.Reflection.Assembly]::LoadFrom("$env:systemroot\system32\inetsrv\Microsoft.Web.Administration.dll")
    $mgr = new-object Microsoft.Web.Administration.ServerManager $applicationHostConfig
    $conf = $mgr.GetApplicationHostConfiguration()
    $section = $conf.GetSection("webFarms")
    $webFarms = $section.GetCollection()
    $webFarm = $webFarms | Where-Object {
        $_.GetAttributeValue("name") -eq $serverFarmName
    }
    $webFarm
}

# Get a specific instance based on its name. i.e. mywebserver.blue
function Get-Server($serverFarmName,$instanceName) {
	$webFarm = Get-ServerFarm $serverFarmName
    $servers = $webFarm.GetCollection()

    $server = $servers | Where-Object {
        $_.GetAttributeValue("address") -eq $instanceName
    }
	return $server;
}

# IIS assigns states to the instances using numbers, this maps the state to a human readable name
function Get-StateName($state){
	switch ($state) {
		0 {return "Available"}
		1 {return "Drain"}
		2 {return "Unavailable"}
		3 {return "Unavailable Gracefully"}
	}
	return "Unknown"
}

# Set an instance to a specific state
function Set-InstanceState($serverFarmName,$instanceName,$state){
	$server = Get-Server $serverFarmName $instanceName

	$arr = $server.GetChildElement("applicationRequestRouting")
	$method = $arr.Methods["SetState"]
	$methodInstance = $method.CreateInstance()

	$methodInstance.Input.Attributes[0].Value = $state
	$methodInstance.Execute()

	$stateName = Get-StateName $state
	Write-Host "Set state of instance $instanceName on farm $serverFarmName to $stateName"
}

# Get the index of the Server Farm in the configuration object, 
# used where we have an array of server farms and need to reference ours specifically
function Get-ServerFarmIndex($serverFarmName) {
	$farmIndex = -1
	$index = 0
	Get-WebConfigurationProperty /webFarms -Name Collection | % {
		if ($_.Name -eq $serverFarmName) {
			$farmIndex = $index
		}
		$index++
	}
	if ($farmIndex -eq -1) {
		Write-Error "Server farm $serverFarmName not found"
		exit(1)
	}
	return $farmIndex;
}

# Get the index of the Server Instance in the configuration object, 
# used where we have an array of server instances and need to reference ours specifically
function Get-InstanceIndex($FarmIndex, $instanceName) {
	$instanceIndex = -1
	$index = 0
	Get-WebConfigurationProperty /webFarms -Name Collection[$farmIndex].Collection | % {
		if ($_.address -eq $instanceName) {
			$instanceIndex = $index
		}
		$index++
	}
	if ($instanceIndex -eq -1) {
		Write-Error "Server instance $instanceName not found"
		exit(1)
	}
	return $instanceIndex;
}

# Check if the server instance is online or offline
function Get-ServerOnline($serverFarmName,$instanceName) {
	$farmIndex = Get-ServerFarmIndex $serverFarmName
	$instanceIndex = Get-InstanceIndex $farmIndex $instanceName

	return Get-WebConfigurationProperty webFarms -Name Collection[$farmIndex].Collection[$instanceIndex].enabled.Value
}

# Take a serve instance offline
function Set-ServerOffline($serverFarmName,$instanceName) {
	$farmIndex = Get-ServerFarmIndex $serverFarmName
	$instanceIndex = Get-InstanceIndex $farmIndex $instanceName

	Write-Host "Taking instance $instanceName on farm $serverFarmName OFFLINE"
	Set-WebConfigurationProperty webFarms -Name Collection[$farmIndex].Collection[$instanceIndex].enabled -Value "False"
}

# Bring a server instance online
function Set-ServerOnline($serverFarmName,$instanceName) {
	$farmIndex = Get-ServerFarmIndex $serverFarmName
	$instanceIndex = Get-InstanceIndex $farmIndex $instanceName

	Write-Host "Bringing instance $instanceName on farm $serverFarmName ONLINE"
	Set-WebConfigurationProperty webFarms -Name Collection[$farmIndex].Collection[$instanceIndex].enabled -Value "True"
}

# Query the requests per second so we can drain the live instance
function Get-RequestsPerSecond($serverFarmName, $instanceName) {
	$server = Get-Server $serverFarmName $instanceName
	$arr = $server.GetChildElement("applicationRequestRouting")
    $counters = $arr.GetChildElement("counters")
    $requests = $counters.GetAttributeValue("requestPerSecond")
	return $requests[0]
}

Export-ModuleMember -Function '*'
