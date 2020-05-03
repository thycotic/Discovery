<#
	.SYNOPSIS

	Discovery script for finding SQL Logins on a given target machine

	.DESCRIPTION

	Find the SQL Logins on all instances found on a given target machine.

	.NOTES

	Depends upon dbatools module being installed on the Secret Server Web Node or the Distributed Engine
	Reference: https://www.powershellgallery.com/packages/dbatools/
	Tested with version 1.0.107
#>
$params = $args

<# Adjust this as required for the secrest you will pass in to utilize #>
$TargetServer = $params[0]

<# Utilize a privileged account to find SQL Logins on each instance #>
$Username = $params[1]
$Password = $params[2]

if ($Username -and $Password) {
	$passwd = $Password | ConvertTo-SecureString -AsPlainText -Force
	$cred = New-Object System.Management.Automation.PSCredential -ArgumentList $Username,$passwd
}

$ProgressPreference = 'SilentlyContinue'
if (-not (Get-InstalledModule dbatools)) {
	throw "The module dbatools is required for this script. Please run 'Install-Module dbatools' in an elevated session on your Distributed Engine and/or Web Node."
} else {
	Import-Module dbatools -Force
	# this config option disables dbatools commands attempting to resolve the server name passed in
	# since our TargetServer is coming from the machine discovery it can be trusted as a valid server
	Set-DbatoolsConfig -FullName commands.resolve-dbanetworkname.bypass -Value $true
}

<# Find all the SQL Server instances #>
try {
	$p = @{
		ComputerName = $TargetServer
		# Credential = $cred
		ScanType = 'SqlService'
		EnableException = $true
	}
	$sqlEngines = Find-DbaInstance @p
} catch {
	throw "No SQL Server services found on $TargetServer`: $($_.Exception)"
}

try {
	$p = @{
		ComputerName = $TargetServer
		# Credential = $cred
		EnableException = $true
	}
	$regRoots = Get-DbaRegistryRoot @p
} catch {
	throw "Issue collecting SQL Server registry information on $TargetServer`: $($_.Exception)"
}

$instances = @()
<# Find the TCP Port configured on each instance #>
$IpAllPath = 'MSSQLServer\SuperSocketNetLib\Tcp\IPAll\'
if ($sqlEngines -and $regRoots) {
	foreach ($engine in $sqlEngines) {
		$currentReg = $regRoots | Where-Object InstanceName -ieq $engine.InstanceName
		$rootPath = $currentReg.RegistryRoot
		try {
			$regPath = Join-Path $rootPath -ChildPath $IpAllPath

			$p = @{
				ComputerName = $TargetServer
				# Credential = $cred
				ErrorAction = 'Stop'
			}
			$port = (Invoke-Command @p -ScriptBlock {Get-ItemProperty -Path $using:regpath}).TcpPort
		} catch {
			Write-Output " Issue capturing TCP port for $engine`: $($_.Exception)"
			continue
		}

		if ($port -and $port -ne 1433) {
			$sqlInstanceValue = "$($currentReg.SqlInstance),$port"
		} else {
			$sqlInstanceValue = ($currentReg.SqlInstance)
		}
		try {
			$p = @{
				SqlInstance = $sqlInstanceValue
				SqlCredential = $cred
			}
			$cn = Connect-DbaInstance @p

			$p = @{
				SqlInstance = $cn
				Type = 'SQL'
				ExcludeFilter = '##*'
				EnableException = $true
			}
			$logins = Get-DbaLogin @p
		} catch {
			Write-Output "Issue connecting to $sqlInstanceValue - $($_.Exception)"
			continue
		}

		foreach ($login in $logins) {
			[PSCustomObject]@{
				Machine = $login.Parent.Name
				Username = $login.Name
				Port = if ($port) {$port} else {$null}
			}
		}
	}
}
