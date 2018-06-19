#Pull the accounts  that are running services on the machine.
$Machine = $Args[0]
$accounts = Get-WMIObject Win32_Service -ComputerName $Machine  | Where-Object{($_.StartName -like ".\*") -and $_.StartName -notlike "*NT *"} 
 
 #In those accounts, find the ones that are local accounts, and add them to an array.
 if ($accounts) {                
 $dependencyaccounts = @()
 foreach($dependency in $accounts)
 {
 $object = New-Object PSObject
 $object | Add-Member -MemberType NoteProperty -Name ServiceName -Value $dependency.DisplayName
 $object | Add-Member -MemberType NoteProperty -Name Enabled -Value $dependency.Started
 if ($dependency.startname.contains('\'))
 {
   $accountinfo = $dependency.startname.split('\')
   $username = $accountinfo[1]
 }
 $object | Add-Member -MemberType NoteProperty -Name Username -Value $username
 $object | Add-Member -MemberType NoteProperty -Name Machine -Value $Machine
 $dependencyaccounts += $object
 $object = $null
 }
 return $dependencyaccounts
 }
 return $null
 
 