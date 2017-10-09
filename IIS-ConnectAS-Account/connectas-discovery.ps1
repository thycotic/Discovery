$computerName=$args[0]
$scriptBlock={
Import-Module WebAdministration
$webSites = Get-Website
$dependencies =@()
ForEach($webSite in $webSites)
{
    $siteName = ($webSite | Select -Property "Name").name
    $filter = "system.applicationHost/sites/site[@name='$siteName']/application[@path='/']/virtualDirectory[@path='/']"
    $username=Get-WebConfigurationProperty $filter -Name "userName" | Where-Object {$_.Value -ne ''}
    $ServiceName=Get-WebConfigurationProperty $filter -Name "physicalPath" | Where-Object{$_.Value -ne ''}
    $path =Get-WebConfigurationProperty $filter -Name "path"| Where-Object {$_.Value -ne ''}

   if($username.Value -eq $null -or $username.Value.Length -eq 0){
        Continue
    }
    else
        {
            #Only get the Directory name from the full path
            $serviceName=$ServiceName.Value.Substring($ServiceName.Value.LastIndexOf('\')+1)
            $domain=$username.Value.Split("\")

            $object=New-Object PSObject
            $object | Add-Member -MemberType NoteProperty ComputerName $env:COMPUTERNAME
            $object | Add-Member -MemberType NoteProperty ServiceName $serviceName
            $object | Add-Member -MemberType NoteProperty VirtualDirectory $path.Value
            $object | Add-Member -MemberType NoteProperty Username $username.Value.Split("\")[1]
            $object | Add-Member -MemberType NoteProperty Domain $domain[0]
            $object | Add-Member -MemberType NoteProperty ItemXPath `"$filter`"

            $dependencies +=$object
        }
}

$virDirs=Get-WebVirtualDirectory
foreach($dir in $virDirs){
    $filter=$dir.ItemXPath
    $filter = $filter.Substring(1)
    $username=Get-WebConfigurationProperty $filter -Name "username"| Where-Object {$_.Value -ne ''}
    $serviceName=Get-WebConfigurationProperty $filter -Name "physicalpath"| Where-Object {$_.Value -ne ''}
    $path =Get-WebConfigurationProperty $filter -Name "path"| Where-Object {$_.Value -ne ''}
    if($username.Value -eq $null -or $username.Value.Length -eq 0){
        Continue
    }
    else{
    #clean up the path
    $path=$path.Value.Substring(1)
    #Only get the Directory name from the full path
    $serviceName=$serviceName.Value.Substring($serviceName.Value.lastindexof('\')+1)
    $domain=$username.Value.Split("\")

    $object=New-Object PSObject
    $object | Add-Member -MemberType NoteProperty ComputerName $env:COMPUTERNAME
    $object | Add-Member -MemberType NoteProperty ServiceName $serviceName
    $object | Add-Member -MemberType NoteProperty VirtualDirectory $path
    $object | Add-Member -MemberType NoteProperty Username $username.Value.Split("\")[1]
    $object | Add-Member -MemberType NoteProperty Domain $domain[0]
    $object | Add-Member -MemberType NoteProperty ItemXPath `"$filter`"
    $dependencies +=$object
    }
}

$apps = Get-WebApplication
foreach($app in $apps){
    $filter=$app.ItemXPath
    $filter = "$filter/virtualDirectory[@path='/']"
    $filter = $filter.Substring(1)

    $username=Get-WebConfigurationProperty $filter -Name "username"| Where-Object {$_.Value -ne ''}
    $serviceName=Get-WebConfigurationProperty $filter -Name "physicalPath"| Where-Object {$_.Value -ne ''}
    $path =Get-WebConfigurationProperty $filter -Name "path"| Where-Object {$_.Value -ne ''}
    if($username.Value -eq $null -or $username.Value.Length -eq 0){
        Continue
    }
    else{
    #Only get the Directory name from the full path
    $serviceName=$ServiceName.Value.Substring($ServiceName.Value.LastIndexOf('\')+1)
    $domain=$username.Value.Split("\")

    $object=New-Object PSObject
    $object | Add-Member -MemberType NoteProperty ComputerName $env:COMPUTERNAME
    $object | Add-Member -MemberType NoteProperty ServiceName $serviceName
    $object | Add-Member -MemberType NoteProperty VirtualDirectory $path.Value
    $object | Add-Member -MemberType NoteProperty Username $username.Value.Split("\")[1]
    $object | Add-Member -MemberType NoteProperty Domain $domain[0]
    $object | Add-Member -MemberType NoteProperty ItemXPath `"$filter`"
    $dependencies +=$object
    }
}
return $dependencies
}
Invoke-Command -ComputerName $computerName -ScriptBlock $scriptBlock