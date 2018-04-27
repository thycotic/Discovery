#path to DLL
try{
$dll = "Oracle.ManagedDataAccess.dll" 
$directoryName=(Get-ChildItem -Path "C:\oracle" -Include $dll -Recurse).DirectoryName
$path = $directoryName+"\"+$dll
Add-Type -Path $path
}

catch 
{
    throw "An Error occured loading the DLL: {0} make sure you install the oracle driver or point to the oracle path" -f $_
}

$username = $args[0]
$password = $args[1]
$server = $args[2]
<#$Sid = ""
$serviceName=""
$connectionString = "Data Source=(DESCRIPTION=(Address_List=(ADDRESS=(PROTOCOL=TCP)(HOST=$server)(PORT=1521)))(CONNECT_DATA=(SID=$Sid))); User Id=$username; Password=$password;"#>
$connectionString = "Data Source=(DESCRIPTION=(Address_List=(ADDRESS=(PROTOCOL=TCP)(HOST=$server)(PORT=1521)))); User Id=$username; Password=$password;"
#create the connection
    try
        {
            $connection = New-Object Oracle.ManagedDataAccess.Client.OracleConnection($connectionString)
            $connection.open()
        }

    catch [Oracle.ManagedDataAccess.Client.OracleException]
        {
            Write-Debug $Error[0].Exception.Message
	          throw "An Error occured openning connection to the database: {0} please check your connection string, and try again" -f $_
        }

#run the query
    try
        {
            $query = "SELECT USERNAME FROM DBA_USERS WHERE ACCOUNT_STATUS = 'OPEN'"
            $command=$connection.CreateCommand()
            $command.CommandText=$query
            $command.CommandTimeout=0
            $dataAdapter=New-Object Oracle.ManagedDataAccess.Client.OracleDataAdapter $command
            $dataSet = New-Object System.Data.DataSet
            $dataAdapter.Fill($dataSet) | Out-Null
            $users= $dataSet.Tables[0]

            #Build the user object
            $oracleUsers = @()
            foreach ($user in $users)
                {
                      $usrObj= New-Object -TypeName PSObject
                      $usrObj| Add-Member -MemberType NoteProperty -Name Server -Value $connection.HostName
                      $usrObj| Add-Member -MemberType NoteProperty -Name Port -Value "1521"
                      $usrObj| Add-Member -MemberType NoteProperty -Name Database -Value $connection.DatabaseName
                      $usrObj| Add-Member -MemberType NoteProperty -Name Username -Value $user.USERNAME
                      $usrObj| Add-Member -MemberType NoteProperty -Name Enabled -Value $true
                      $oracleUsers +=$usrObj
                  }
                return $oracleUsers
        }

    catch [Oracle.ManagedDataAccess.Client.OracleException]
        {
            Write-Debug $Error[0].Exception.Message
            throw "An Error occured running the query or building the user object: {0}" -f $_
        }

    finally
            {
                $connection.Dispose()
            }
