#Pull the accounts  that are running services on the machine.
$machine = $args[0]
try {
    $services = @(Get-WMIObject Win32_Service -ComputerName $machine  | Where-Object{($_.StartName -like ".\*") -and $_.StartName -notlike "*NT *"})
}
catch {
    throw $_.Exception.Message
}
 #In those accounts, find the ones that are local accounts, and add them to an array.
 if ($services.count -ne 0) {                
    $serviceAccounts = @()
    $services.ForEach({
        $object = "" | Select-Object DisplayName, Started, Username, Machine
        $object.DisplayName = $_.DisplayName
        $object.Started = $_.Started
        $object.Username = $(if($_.startname.contains("\")) { $_.startname.split("\")[1] })
        $object.Machine = $machine
        $serviceAccounts +=$object
    });
    return $serviceAccounts
 }
else {
    throw "No local account dependencies found"
}