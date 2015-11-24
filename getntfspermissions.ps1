function getNamefromSID ($SID) {
		try {
		$objSID = New-Object System.Security.Principal.SecurityIdentifier ($SID)
		$objUser = $objSID.Translate( [System.Security.Principal.NTAccount])
		}
		catch {return $false}
		return $objUser.Value
}

function getSidFromName ($Name) {
		try {
		$objUser = New-Object System.Security.Principal.NTAccount($Name)
		$strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
		}
		catch {return $false}
		return $strSID.Value
}

function getCleanAcl($acls,$fpath) {
	$psArray = @()
	foreach ($acl in $acls) {
		if (isClean($acl.IdentityReference)) {
			$psArray += addLine $fpath $(getSidFromName($acl.IdentityReference)) $acl.FileSystemRights $acl.AccessControlType
		}
	}
	return $psArray
}

function addLine ($path,$sid,$rule,$acl) {
			$psObject = New-Object psobject
			Add-Member -InputObject $psobject -MemberType noteproperty -Name "PATH" -Value $path
			Add-Member -InputObject $psobject -MemberType noteproperty -Name "SID" 	-Value $sid
			Add-Member -InputObject $psobject -MemberType noteproperty -Name "Rule" -Value $rule
			Add-Member -InputObject $psobject -MemberType noteproperty -Name "ACL"	-Value $acl
			return $psObject
}

function getFinalTableofSid ($cleanacl,$sddl) {
	$psArray = @()
	# Split on ; result on table of values, the SID having conditionnal members will be on distinct line
	$temp = $sddl.Split(";")
	$min  = 0
	foreach ($line in $cleanacl) {
			$found = $false
			if ($temp) {
				# Check the table
				for ($i=$min; $i -lt $temp.Length-1; $i++) {
					# When you find the parentsid on a distinct line
					if ($temp[$i] -eq $line.SID) {
						# Next time start from $i+1
						$min = $i + 1
						# Intialize an array
						$arrmatch =@()
						# Get conditionnal values
						$conditionnal = $temp[$i+1]
						# Get Table of conditionnal values
						Select-String "S\-\d\-\d\-\d{2}\-\d{10}\-\d{10}\-\d{10}\-\d{4}" -input $conditionnal -AllMatches | Foreach {$arrmatch += $_.matches.Value}
						if ($arrmatch) {
							$found = $true
							foreach ($mat in $arrmatch) {
								$psArray += addLine $line.PATH $(getNamefromSID($mat)) $line.Rule $line.ACL
							}
						}	
					}
					if ($found) {break}
				}
			}
			if (!$found) { $psArray += addLine $line.PATH $(getNamefromSID($line.SID)) $line.Rule $line.ACL }
	}
	return $psArray
}

function isClean ($string) {
	if (($string -match "MERITISNET") -and ($string -NotMatch "Administrateur")) {return $true}
	return $false
}

function getConditionalSID ($sddl,$parentsid) {

	# Split on ; result on table of values, the SID having conditionnal members will be on distinct line
	$temp = $sddl.Split(";")
	if ($temp) {
		# Check the table
		for ($i=0; $i -le $temp.Length; $i++) {
			# When you find the parentsid on a distinct line
			if ($table[$i] -eq $parentsid) {
				# Intialize an array
				$arrmatch =@()
				# Get conditionnal values
				$conditionnal = $table[$i+1]
				# Get Table of conditionnal values
				Select-String "S\-\d\-\d\-\d{2}\-\d{10}\-\d{10}\-\d{10}\-\d{4}" -input $sddl -AllMatches | Foreach {$arrmatch += $_.matches.Value}
			}
		}
	}
}

function getPerm($rootfolder,$outFile)	 {
	clear
	Write-Host "Generating Permissions file ..."
	$arr =@()
	
	$files = Get-ChildItem "$rootfolder","$rootfolder\*\*","$rootfolder\*\*\*","$rootfolder\*\*\*\*" -Directory
	
	$a		= 0
	$sum	= $files.count 
	$files | % {
		# Show progress
		$b = "{0:N0}" -f ($a * 100)
		Write-Progress -Activity "Working..." -PercentComplete "$b" -CurrentOperation "$b % complete"
		$a = ($a+1/$sum)
		# Initialize variables
		$osObject = $null
		$psObject = New-Object psobject
		
		# Get full name with path
		$fpath 		=  $_.FullName
		
		# Get Acls
		$acls 		=  Get-Acl $fpath 
     	# GET Clean Access without System and Administrator .. on this format PATH | SID | Rule | Access |
		$cleanacl 	= getCleanAcl $acls.Access $fpath 
		
		# Get the SDDL
		$sddl 		= $acls.Sddl

		# Get Table of All users with Access (Conditionnal users included)
		
		$tableofsid	= getFinalTableofSid $cleanacl $sddl
		# Add the tableofsid to the final array to be exported
		
		$arr += $tableofsid
			
		}
		Write-Host "Generating $outFile"
		$arr | select * | Export-Csv -Path $outFile -NoType -encoding "unicode" -force
		Write-Host "Generating $outFile ---- OK"

}

#Main
$outFolder 		= "D:\Shares\Fileshare\"
$inFolder 		= "D:\Out\"

getPerm "$inFolder" 		"$outFolder\Permissions.csv"
