Function Get-LocalAdmins {
    [Cmdletbinding()]
     Param (
        [string]$ComputerName,
        [string]$GroupName,
        [string]$Username,
        [string]$Password
    )
    Begin {
        $users = @();
        #Convert disabled User flags to readable format. Credit Boe Prox
        Function Convert-UserFlag  {
            Param ($UserFlag)
            $List = New-Object System.Collections.ArrayList
            Switch  ($UserFlag) {
                ($UserFlag  -BOR 0x0002)  {
                    [void]$List.Add('Disabled');
                }
            }
            return $List
        }
    }# End Begin Block
 
    Process {
        try{
            $ports=@(135,445).ForEach({
                Test-NetConnection -ComputerName $ComputerName -Port $_ -InformationLevel Quiet -ErrorAction Stop | Out-Null
            });
        }
        catch{
            throw "Port Scan Error: {0}" -f $_.exception.message
        }
        try{
            $endPoint = "WinNT://$ComputerName/$GroupName,group"
            $group = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $endPoint,$Username, $Password -ErrorAction Stop
        }
        catch{
            throw "Error connecting to machine: {0}" -f $_.exception.message
        }
        try{
            $members = @($group.Invoke("Members"));
        }
        catch {
            throw "Error expanding group memebers: {0}" -f $_.exception.message
        }#end catch
        $members.ForEach({
            $name = $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null);
            $adsPath = $_.GetType().InvokeMember("ADsPath", 'GetProperty', $null, $_, $null);
            $class= $_.GetType().InvokeMember("Class", 'GetProperty', $null, $_, $null)
            if($class -eq "user"){
                $userFlags = $_.GetType().InvokeMember("UserFlags", 'GetProperty', $null, $_, $null);
            }
            $status = Convert-UserFlag -UserFlag $userFlags
            if($status -ne "Disabled" -and $class -eq "user" ) {
                # If the account is local, then add it to the object
                if ($adsPath -like "*/$ComputerName/*") {
                    $userObj = "" | Select-Object Machine,Username,Enabled
                    $userObj.Machine = $ComputerName
                    $userObj.Username = $name
                    $userObj.Enabled = $true
                    $users += $userObj
                }
            }
        });
        return $users
    }#End Process Block
}#Fuction End
#we need to split the FQDN from the machine name
$computerName = $args[0].split(".")[0]
Get-LocalAdmins -ComputerName $computerName -GroupName "Administrators" -Username $args[1] -Password $args[2] -ErrorAction stop