$privUser = $args[0]
$privPassword = ConvertTo-SecureString $args[1] -AsPlainText -Force
$privDomain =  $args[2]
$ComputerName = $args[3]
$Creds =  New-Object System.Management.Automation.PSCredential ($privUser, $privPassword)

$script = {
    $checkRegistry = Get-ItemProperty "hklm:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" | Select DefaultDomainName, DefaultUserName
    $DefaultDomainName = $checkRegistry.DefaultDomainName
    $DefaultUserName=$checkRegistry.DefaultUserName
try 
{
    $Application = "autologon.exe"
    $GetAutoLogon=Get-ChildItem -Path <path to autologo.exe> -ErrorAction Stop | where {$_.Name -eq $Application}
    $ServiceName = $GetAutoLogon.Name
    $Dependency = @()
    $userObj = New-Object -TypeName psobject
    $userObj | Add-Member -MemberType NoteProperty -Name Machine -Value $env:COMPUTERNAME
    $userObj | Add-Member -MemberType NoteProperty -Name ServiceName -Value $ServiceName
    $userObj | Add-Member -MemberType NoteProperty -Name Username -Value $DefaultUserName
    $userObj | Add-Member -MemberType NoteProperty -Name Domain -Value $DefaultDomainName
    $Dependency +=$userObj
    return $Dependency;

}
catch [System.Management.Automation.ItemNotFoundException]
{
    throw "No AutoLogon Dependencies found on $env:COMPUTERNAME" #needed till we fix discovery. Not adding "throw" will result in "No Dependencies Found" error for computers without autologn
}
}
Invoke-Command -ComputerName $ComputerName -ScriptBlock $script
