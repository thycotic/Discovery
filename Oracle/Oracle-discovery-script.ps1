# Test access to DLL
try{
    $OMDA = "Oracle.ManagedDataAccess.dll" 
    $directoryName=(Get-ChildItem -Path "C:\oracle" -Include $OMDA -Recurse).DirectoryName
    $path =$("$directoryName\$OMDA")
    Add-Type -Path $path
}
catch {
    throw "An error occured loading the Oracle Data Provider: $($_.Exception.Message)"
}

Function Get-OracleAccounts{
    Param (
        [string]
        $UserName,
        [string]
        $Password,
        [string]
        $ComputerName,
        [string]
        $ServiceName,
        [string]
        $Port
    )
    process{
        $connectionString =
@"
Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$ComputerName)(PORT=$Port))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ServiceName)));User Id="$UserName";Password=$Password
"@
        try{
            $connection = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($connectionString)
            $connection.open()
        }
        catch [Oracle.ManagedDataAccess.Client.OracleException]{
	        throw "Connection error: $($_.Exception.Message)"
        }
        try{
            $query = "SELECT * FROM DBA_ROLE_PRIVS WHERE GRANTED_ROLE = 'DBA'"
            $command=$connection.CreateCommand()
            $command.CommandText=$query
            $command.CommandTimeout=0
            $dataAdapter=New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter $command
            $dataSet = New-Object System.Data.DataSet
            $dataAdapter.Fill($dataSet) | Out-Null
            if($dataSet.Tables[0] -ne $null){
                $table= $dataSet.Tables[0]
            }
            else {
                $table = New-Object System.Collections.ArrayList
            }
            return $table
        }
        catch [Oracle.ManagedDataAccess.Client.OracleException]{
            throw "An Error occured running the query$($_.Exception.Message)"
        }
        finally {
            $connection.Close()
            $connection.Dispose()
        }
    }
}

# Grab Ports for Oracle Listeners

$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $args[0], $(ConvertTo-SecureString -AsPlainText $args[1] -Force)
#$credential = Get-Credential
try{
    $sshSession = New-SSHSession -ComputerName $args[2] -Credential $credential -Port 22 -Force -ErrorAction Stop
}
catch{
    throw "Error connecting to $($args[2]): $($_.Exception.Message)"
}
try {
    # REPLACE home path of Discovery User Account - D
    $command =Invoke-SSHCommand -Command "/home/thyco/discover.sh" -SSHSession $sshSession
    # This will grab the file which is created by bash script on linux system
    Get-SCPFile -ComputerName $args[2] -Credential $credential -Port 22 -RemoteFile "/home/thyco/oracleinfo.txt" -LocalFile "oracleinfo.txt"
    Remove-SSHSession -SSHSession $sshSession | Out-Null
}
catch {
    throw "Error running Discover.sh and receiving ports: $($_.Exception.Message)"
}

# BUILD arrays of the connection details from oracleinfo file
$services=@()
$ports=@()
$oraconnections = Get-Content "oracleinfo.txt"
foreach ($line in $oraconnections){$ports+= $line.Split(" ")[0]}
foreach ($line in $oraconnections){$services+= $line.Split(" ")[1]}

#Build the user object
$Accounts = @()
if($services.Count -ne 0){
    try {
        $s = 0
        $services.ForEach({
            $serviceName = $services[$s]
            $ServicePort = $ports[$s]
            $results= @(Get-OracleAccounts -UserName $args[3] -Password $args[4] -ComputerName $args[2] -ServiceName $serviceName -Port $ServicePort)
            $results.ForEach({
                $usrObj= "" | Select-Object Machine, UserName, Role, Database,Port, Enabled
                $usrObj.Machine = $args[2]
                $usrObj.Port = "1521"
                $usrObj.Database = $serviceName
                $usrObj.UserName = $_.GRANTEE
                $usrObj.Role = $_.GRANTED_ROLE
                $usrObj.Enabled = $true
                $Accounts +=$usrObj
            });
            $s++
        });
        return $Accounts
    }
    catch {
        throw $_.Exception.Message
    }
}
else {
    throw "No Oracle instances running on machine"
}