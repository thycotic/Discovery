$computerName = $args[0]
function Invoke-SqlCommand {
    [cmdletbinding(DefaultParameterSetName="integrated")]
    Param (
        [Parameter(Mandatory=$true)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Username,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Password,
        [Parameter(Mandatory=$false, ParameterSetName="integrated")][switch]$UseWindowsAuthentication,
        [Parameter(Mandatory=$false)][int]$CommandTimeout=0
    )
    #build connection string
    $connstring = "Server=$Server; Database=$Database; "
    If ($PSCmdlet.ParameterSetName -eq "not_integrated") {
        $connstring += "User ID=$Username; Password=$Password;"
    }
    elseif ($PSCmdlet.ParameterSetName -eq "integrated") {
        $connstring += "Trusted_Connection=Yes; Integrated Security=SSPI;"
    }
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
    $connection.Open()
    #build query object
    $command = $connection.CreateCommand()
    $query="SELECT loginname, dbname 
            FROM syslogins 
            WHERE hasaccess = 1 
            AND [password] is not null 
            AND (sysadmin = 1 or securityadmin = 1 or serveradmin = 1) 
            AND isntname = 0"
    $command.CommandText = $query  
    $command.CommandTimeout = $CommandTimeout
    #run query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | out-null
    #return the first collection of results or an empty array
    If ($dataset.Tables[0] -ne $null) {
        $table = $dataset.Tables[0]
    }
    elseif ($table.Rows.Count -eq 0) {
        $table = New-Object System.Collections.ArrayList
    }
    $connection.Close()
    return $table
}#end function
#function to test ports
function Test-Port {
    Param(
        [string]$ComputerName,
        [int]$Port,
        [int]$Timeout,
        [switch]$Verbose
    )
    $ErrorActionPreference = "SilentlyContinue"
    # Create TCP Client
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    # Begin Async connection to remote host on specified port
    $beginConnect = $tcpClient.BeginConnect($ComputerName,$Port,$null,$null)
    # Set the wait time
    $wait = $beginConnect.AsyncWaitHandle.WaitOne($Timeout,$false)
    # Check to see if the connection is done
    if(!$wait) {
        # Close the connection and report timeout
        $tcpClient.Close()
        if($Verbose){
            Write-Host "Connection Timeout"
        }
        return $false
    }
    else {
        # Close the connection and report the error if there is one
        $error.Clear()
        $tcpclient.EndConnect($beginConnect) | out-Null
        if(!$?){
            if($verbose){
                Write-Host $_.Exception.Message
            }
            $failed = $true
        }
        $tcpclient.Close()
    }
    # Return $true if connection Establish else $False
    if($failed) {
        return $false
    }
    else {
        return $true
    }
}
#check for SQL server
try {
    $port=Test-Port -ComputerName $computerName -Port 445 -Timeout 30000
    if(!$port) {
        throw "Connection timeout"
    }
    $sqlService = @(Get-Service -ComputerName $computerName -DisplayName "SQL Server (*", "MSSQL$*"| Where {$_.Status -eq "Running"} -ErrorAction Stop)
}
catch {
    throw "Error connecting to ${computerName}: $($_.Exception.Message)"
}
#initialize the accounts array
$accounts = @()  
if($sqlService.Count -ne 0) {
    try {
    $sqlService.ForEach({
        if ($_.Name -ne 'MSSQLSERVER') {
            $sqlInstance = "$computerName\$($_.Name.Split('$')[1])"
        }
        else {
            $sqlInstance = $computerName
        }
        #we insert the resutls in an array in case we only get one account back. Not doing so will throw a method doesn't exist error when calling the ForEach method
        $table = @(Invoke-SqlCommand -Server $sqlInstance -UseWindowsAuthentication)
        $table.forEach({
            $account = "" | Select-Object Machine, UserName, Database, Enabled
            $account.Machine = $sqlInstance;
            $account.UserName = $_.loginname;
            $account.Database = $_.dbname;
            $account.Enabled = $true;
            $accounts +=$account
        });
    });
    return $accounts
    }
    catch {
        throw "SQL error: $($_.Exception.Message)"
    }

}
else {
    throw "No SQL Servers Found on Computer"
}
