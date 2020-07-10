<#
.DESCRIPTION
    Account discovery script for HPE/Aruba switches via PoSH-SSH.
.NOTES
    Argument list must be specified in the following order: target, username, password.

    Author:     Zach Choate (KSM Consulting)
    Modified:   07/07/2020

#>

Function Invoke-AccountDiscovery {
    <#
    .PARAMETER target
        IP address or hostname of target to scan.
    .PARAMETER username
        User that has access to pull running-config of switch.
    .PARAMETER password
        Password for user.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$True)]
        [String] $target,
        [Parameter(Mandatory=$True)]
        [String] $username,
        [Parameter(Mandatory=$True)]
        [String] $password
    )
    
        Import-Module Posh-SSH
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        $creds = New-Object -TypeName System.Management.Automation.PSCredential ($Username, $securePassword)
        try{
            $session = New-SSHSession -ComputerName $target -Credential $creds -ConnectionTimeout 99999 -AcceptKey -Force
            $SSHStream = New-SSHShellStream -SSHSession $session -TerminalName 'dumb' -Rows 5000
            Start-Sleep -Seconds 5
            $SSHStream.Write("`n")
            Start-Sleep -Seconds 3
            $SSHStream.Write("show running-config`n")
            Start-Sleep -Seconds 5
            $runningconfig = $SSHStream.Read()
            $SSHStream.Write("exit`n")
            Start-Sleep -Seconds 2
            $SSHStream.Write("exit`n")
            Start-Sleep -Seconds 5
            $SSHStream.Write("y`n")
            $SSHStream.Close()
            $accounts = @()
            $lines = $runningconfig -split "`n"
            try{
                $hostname = ((($lines | Select-String -Pattern 'hostname\s\"(.+)' -AllMatches) -split ' "')[1]) -replace '"',""
            } catch {
                $hostname = $target
            }
            foreach($line in $lines){
                $account = "" | Select-Object machine, username, hostname
                $account.username = $((($line | Select-String -Pattern 'password\s(.+)' -AllMatches) -split " ")[1])
                if(!($account.username)) { continue }
                $account.machine = $target
                $account.hostname = $hostname
                $accounts +=$account
            }
           
            if($accounts.count -ne 0){
                return $accounts
            }
            else {
                throw "No Accounts Found"
            }
        }
        catch{
                Throw "Invalid Password, please ensure the password is correct. Attempted authentication with $($args[1]). " + $_
        }
     
    
    
    }
    
    Invoke-AccountDiscovery -Target $args[0] -Username $args[1] -Password $args[2]    