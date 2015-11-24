$New = read-host "Please enter your PC name: "
$Old = $env:computername
Rename-Computer -NewName $New -ComputerName $Old -DomainCredential XXXXXXx\Administrateur -Restart
