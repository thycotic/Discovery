# Thycotic Extensible Discovery - Oracle

# Test access to DLL
$LinuxUser = $args[0]
$LinuxPass = $args[1]
$Target = $args[2]
$OracleUser = $args[3]
# Only necessary if using hyphen in username...
# $OracleUser = $OracleUser.Trim("`"")
$OraclePass = $args[4]

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
            Write-Debug "opening oracle connection $ConnectionString"
            $connection.open()
                
                try{
                        Write-Debug "Opened oracle connection"
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
                throw "An Error occured running the query: $($_.Exception.Message)"
            }
        }
         catch{
             write-debug "Connection error: $($_.Exception.Message)"

         }   

     }
    
            
}

# Grab Ports for Oracle Listeners
Import-Module -Name Posh-SSH
$credential = New-Object System.Management.Automation.PSCredential -ArgumentList $LinuxUser, $(ConvertTo-SecureString -AsPlainText $LinuxPass -Force)
#$credential = Get-Credential
try{
    $sshSession = New-SSHSession -ComputerName $Target -Credential $credential -Port 22 -Force -ErrorAction Stop
 
}
catch{
    throw "Error connecting to $($Target): $($_.Exception.Message)"
}
try {
    # REPLACE home path of Discovery User Account - D
    Set-SCPFile -ComputerName $Target -Credential $credential -Port 22 -LocalFile "C:\Users\svc-Thycoticadm\discover.sh" -RemotePath "/home/svc-thycoadm/" -Force -NoProgress
    $command =Invoke-SSHCommand -Command "chmod +x /home/svc-thycoadm/discover.sh" -SSHSession $sshSession
    $command =Invoke-SSHCommand -Command "/home/svc-thycoadm/discover.sh" -SSHSession $sshSession
    # This will grab the file which is created by bash script on linux system
    Get-SCPFile -ComputerName $Target -Credential $credential -Port 22 -RemoteFile "/home/svc-thycoadm/oracleinfo.txt" -LocalFile "C:\Users\svc-Thycoticadm\oracleinfo.txt" -Force -NoProgress
    $command =Invoke-SSHCommand -Command "rm /home/svc-thycoadm/discover.sh" -SSHSession $sshSession
    $command =Invoke-SSHCommand -Command 'rm /home/svc-thycoadm/oracleinfo.txt' -SSHSession $sshSession
    Remove-SSHSession -SSHSession $sshSession | Out-Null
}
catch {
    throw "Error running Discover.sh and receiving ports: $($_.Exception.Message)"
}

# BUILD arrays of the connection details from oracleinfo file
$services=@()
$ports=@()
$oraconnections = Get-Content "C:\users\svc-Thycoticadm\oracleinfo.txt"
foreach ($line in $oraconnections){$ports+= $line.Split(" ")[0]}
foreach ($line in $oraconnections){$services+= $line.Split(" ")[1]}

# DEBUG ONLY...
#$ports >> 'C:\users\svc-thycoticadm\portlog.txt'
#$services >> 'C:\users\svc-thycoticadm\servicelog.txt'

#Build the user object
$Accounts = @()
if($services){
    try {
        $s = 0
        $services.ForEach({
            $serviceName = $services[$s]
            $ServicePort = $ports[$s]
            $results= @(Get-OracleAccounts -erroraction silentlycontinue -UserName $OracleUser -Password $OraclePass -ComputerName $Target -ServiceName $serviceName -Port $ServicePort)
            $results.ForEach({
               $usrObj= New-Object -TypeName psobject 
                $usrObj | Add-Member -MemberType NoteProperty -Name Machine -Value $Target
                $usrObj | Add-Member -MemberType NoteProperty -Name Port -Value $ServicePort
                $usrObj | Add-Member -MemberType NoteProperty -Name Database -Value $serviceName
                $usrObj | Add-Member -MemberType NoteProperty -Name UserName -Value $_.GRANTEE
                $usrObj | Add-Member -MemberType NoteProperty -Name Role -Value $_.GRANTED_ROLE
                $usrObj | Add-Member -MemberType NoteProperty -Name Enabled -Value $true

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
