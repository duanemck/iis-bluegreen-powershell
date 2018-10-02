function Import-ModuleRemotely([string] $ModuleName, [System.Management.Automation.Runspaces.PSSession] $Session) {
    Write-Host "Copying module $moduleName to the remote machine so it can be loaded remotely"
    function remote( [scriptblock] $Script ) { Invoke-Command -Session $Session -ScriptBlock $Script }

    $module = Get-Module $ModuleName | select -First 1
    if ( !$module ) {
        $module = Get-Module $ModuleName -ListAvailable | select -First 1
        if ( !$module ) { throw "Can't find local module '$ModuleName'" }
    }

    $module_path = Split-Path $module.Path

    $remote_path = remote {
        $p = "$Env:TEMP\remote_module"
        rm "$p\$using:ModuleName" -Recurse -ea 0
        mkdir -Force $p | Out-Null
        $p
    }
    Copy-Item "$module_path\$ModuleName.psm1" "$remote_path\$ModuleName.psm1" -ToSession $Session -Force -Recurse
    remote { import-module -Force $using:remote_path\$using:ModuleName }
}

function Invoke-ScriptRemotely([string] $localScriptFile, [System.Management.Automation.Runspaces.PSSession] $Session, $argumentList) {
    Write-Host "======================================================================================================="
    Write-Host "                         Running $localScriptFile on remote machine"
    Write-Host "-------------------------------------------------------------------------------------------------------"
    $result = Invoke-Command -Session $session -FilePath $localScriptFile -ArgumentList $argumentList
    Write-Host "======================================================================================================="
    return $result
}

function Get-ServerCredentials([string] $username, [string]$password) {
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $credential = New-Object -TypeName "System.Management.Automation.PSCredential" -ArgumentList $username, $securePassword
    return $credential
}

Export-ModuleMember -Function '*'
