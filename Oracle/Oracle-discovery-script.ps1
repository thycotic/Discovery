#path to DLL
try{
    $OMDA = "Oracle.ManagedDataAccess.dll" 
    $directoryName=(Get-ChildItem -Path "C:\oracle" -Include $OMDA -Recurse).DirectoryName
    $path =$("$directoryName\$OMDA")
    Add-Type -Path $path
}

catch {
    throw "An Error occured loading the Oracle Data Provider: $($_.Exception.Message)"
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
        $ServiceName
    )
    process{
        $connectionString =
@"
Data Source=(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$ComputerName)(PORT=1521))(CONNECT_DATA=(SERVER=DEDICATED)(SERVICE_NAME=$ServiceName)));User Id="$UserName";Password=$Password
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
##
##
#Start an SSH session to get the oracle instances
##
##
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $args[0], $(ConvertTo-SecureString -AsPlainText $args[1] -Force)
try{
    $sshSession = New-SSHSession -ComputerName $args[2] -Credential $credential -Port 22 -Force -ErrorAction Stop
}
catch{
    throw "Error connecting to $($args[2]): $($_.Exception.Message)"
}
try {
    $command =Invoke-SSHCommand -Command "ps -ef |grep pmon" -SSHSession $sshSession
    Remove-SSHSession -SSHSession $sshSession | Out-Null
}
catch {
    throw $_.Exception.Message
}
$serviceNames=@($command.OutPut.forEach({
    if($_ -like "*oracle*"){
        $_.SubString($_.LastIndexOf("_")+1)
    }
});)
##
##
#Build the user object
##
##
$Accounts = @()
if($serviceNames.Count -ne 0){
    try {
        $serviceNames.ForEach({
            $serviceName = $_
            $results= @(Get-OracleAccounts -UserName $args[3] -Password $args[4] -ComputerName $args[2] -ServiceName $serviceName)
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