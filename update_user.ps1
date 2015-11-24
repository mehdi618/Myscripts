##### Connection to AD

#  $UserCredential = Get-Credential 
#  try {
#  $Session = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri https://outlook.office365.com/powershell-liveid/ -Credential $UserCredential -Authentication Basic -AllowRedirection -EA SilentyContinue
#  Import-PSSession $Session
#  }
#  Catch {Write-Host "Unable to connect to Office 365"}
##### Main
#$ErrorActionPreference = "Stop"

$exceptions = @('xxxx.xxxx','')
$cal = @('Calendar','Calendrier')

$mails = get-mailbox -ResultSize Unlimited
$mails | Where-Object {$_.Alias -match '\.' -and ($exceptions -NotContains $_.Alias)} | ForEach-Object {


#Remove-Item	$defaultpermission
$name = $_
$calendar = get-mailboxfolderstatistics "$name" | where-object {$_.identity -eq "$name\Calendar"}
if ($calendar) 		{$defaultpermission = $(Get-MailboxFolderPermission -Identity $_":\Calendar" -User "Default" ).AccessRights;$lang="en"}
else 				{$calendar = get-mailboxfolderstatistics "$name" | where-object {$_.identity -eq "$name\Calendrier"}}
if ($calendar) 		{$defaultpermission = $(Get-MailboxFolderPermission -Identity $_":\Calendrier" -User "Default" ).AccessRights;$lang="fr" }
else {Write-Host "No Calendar folder !"}

if ($lang -eq "en") {Write-Host "$name Calendar has $defaultpermission access by default"}
else {Write-Host "$name Calendrier has $defaultpermission access by default"}
}


#Set-MailboxFolderPermission -Identity $_":\Calendar" -User Default -AccessRights Reviewer


##### End
#Remove-PSSession $Session