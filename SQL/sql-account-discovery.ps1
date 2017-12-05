$ComputerName = "SQL"
#check for SQL server
try{
$GetSqlService = Get-WmiObject -Class win32_service -ComputerName $ComputerName -ErrorAction Stop| Where {$_.Name -Like "*MSSQL*"}
}
catch [System.Runtime.InteropServices.COMException]{
Write-Debug "The computer '$ComputerName' does not exist or is inaccessible"
Write-Debug "Exception Message: $($_.exception.message)"
Write-Debug "Stacktrace: $($_.exception.stacktrace)"
}
if($GetSqlService -ne $NULL){

function Invoke-SqlCommand() {
    [cmdletbinding(DefaultParameterSetName="integrated")]Param (
        [Parameter(Mandatory=$true)][Alias("Serverinstance")][string]$Server,
        [Parameter(Mandatory=$true)][string]$Database,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Username,
        [Parameter(Mandatory=$true, ParameterSetName="not_integrated")][string]$Password,
        [Parameter(Mandatory=$false, ParameterSetName="integrated")][switch]$UseWindowsAuthentication = $true,
        [Parameter(Mandatory=$true)][string]$Query,
        [Parameter(Mandatory=$false)][int]$CommandTimeout=0
    )

    #build connection string
    $connstring = "Server=$Server; Database=$Database; "
    If ($PSCmdlet.ParameterSetName -eq "not_integrated") { $connstring += "User ID=$Username; Password=$Password;" }
    ElseIf ($PSCmdlet.ParameterSetName -eq "integrated") { $connstring += "Trusted_Connection=Yes; Integrated Security=SSPI;" }
    
    #connect to database
    $connection = New-Object System.Data.SqlClient.SqlConnection($connstring)
    $connection.Open()
    
    #build query object
    $command = $connection.CreateCommand()
    $command.CommandText = $Query
    $command.CommandTimeout = $CommandTimeout
    
    #run query
    $adapter = New-Object System.Data.SqlClient.SqlDataAdapter $command
    $dataset = New-Object System.Data.DataSet
    $adapter.Fill($dataset) | out-null
    
    #return the first collection of results or an empty array
    If ($dataset.Tables[0] -ne $null) {$table = $dataset.Tables[0]}
    ElseIf ($table.Rows.Count -eq 0) { $table = New-Object System.Collections.ArrayList }
    
    $connection.Close()
    return $table
}

$sql = "select * from master..syslogins where hasaccess = 1 and [password] is not null and (sysadmin = 1 or securityadmin = 1 or serveradmin = 1)"
$database = "master"

try {
if ($GetSqlService.Name -ne 'MSSQLSERVER')
    {
        $SQLService=$GetSqlService.Name.Split('$')[1]
    }

 $targetInstance = $ComputerName+"\"+$SQLService
 $table = Invoke-SqlCommand -Server $targetInstance  -Database $database -Query $sql -UseWindowsAuthentication
$users = @()
 
 foreach ($user in $table) 
     {
         $accountName =$user.loginname
         
         $object = New-Object PSObject;
  
         $object | Add-Member -MemberType NoteProperty -Name Machine -Value ($ComputerName+"\"+$SQLService);
         $object | Add-Member -MemberType NoteProperty -Name UserName -Value $accountName;
         $object | Add-Member -MemberType NoteProperty -Name Database -Value 'master';
         $object | Add-Member -MemberType NoteProperty -Name Enabled -Value  $true;
         
 
         $users +=$object
     }
 
 
 return $users

}
catch {
    Write-Debug ("Can't open connection: {0}`n{1}" -f `
    $server, $_.Exception.ToString())
}

}
else{
throw "No SQL Accounts Found on Computer"

}
