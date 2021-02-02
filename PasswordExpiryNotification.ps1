## Author: Danijel Gerbez
## Last Change: 05/08/2020
## Added exclusion list for users "Where-Object {$_.Name -notlike "*username*" -and $_.Name -notlike "*username*"}"
## Change Made: Initial Deployment
## ---------------------------------
 
#Import AD Module, if error stop
Import-Module ActiveDirectory -ErrorAction Stop
 
#Ten, Five, Three and One Day Warning Date
$TenDays = (get-date).AddDays(10).ToLongDateString()
$FiveDays = (get-date).AddDays(5).ToLongDateString()
$ThreeDays = (get-date).adddays(3).ToLongDateString()
$OneDay = (get-date).adddays(1).ToLongDateString()
 
#General Email Variables
$MailSender = "Sender_Email_Address@somedomain.com"
$Subject = 'Password Expiry Notification'
$EmailStub1 = 'This is an automated message to inform you that the Windows password for the user'
$EmailStub2 = 'will expire in'
$EmailStub3 = 'days from now on'
$EmailStub4 = '. You do not have to change your password immediately but please plan to do so in the next few days. '
$EmailStub5 = 'If you are having issues changing your password please review following documents that will walk you through. How To Change Computer Password - Link to directions'
$EmailStub6 = '. If you are having issues changing your password while connected via VPN please take a look at this document: How To Change Password While On VPN - Link to directions'
$EmailStub7 = '. If you are still having issues please submit a ticket at Link to Helpdesk Here and someone will help you.'
$ChPwdNow = '. Change your password as soon as possible today.'
$HowToNormal = 'To change your password while in some place: Press Ctrl + Alt + Del and select "Change Password" option.'
#$HowToVPN = 'To change password while connected via VPN: 1. Connect to VPN 2. Press Ctrl + Alt + Del and select "Change Password" option.'
$SMTPServer = 'SMTP_Server@somedomain.com"
 
#Look for accounts that are not disabled and do not have "password never expires" setting
$users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False -and PasswordLastSet -gt 0} `
 -Properties "Name", "EmailAddress", "msDS-UserPasswordExpiryTimeComputed" -SearchBase "DC=somedomain,DC=local" | ` Select-Object -Property "Name", "EmailAddress", `
 @{Name = "PasswordExpiry"; Expression = {[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed").tolongdatestring() }}

#Test the output
#Write-Host $users


#Check expiration and send email 
foreach ($user in $users | Where-Object {$_.Name -notlike "*Exclude specific user here*"}) {
     if ($user.PasswordExpiry -eq $TenDays) {
         $days = 10
         $EmailBody = $EmailStub1, '"', $user.name, '"', $EmailStub2, $days, $EmailStub3, $TenDays, $EmailStub4, $EmailStub5, $EmailStub6, $EmailStub7 -join ' '
 
         Send-MailMessage -To $user.EmailAddress -From $MailSender -SmtpServer $SMTPServer -Subject $Subject -Body $EmailBody
              
         Write-Output $user | add-content C:\PwdLogs\$(get-date -f yyyy-MM-dd)_PwLog_10Days.log
     }
      elseif ($user.PasswordExpiry -eq $FiveDays) {
         $days = 5
         $EmailBody = $EmailStub1, '"', $user.name, '"', $EmailStub2, $days, $EmailStub3, $FiveDays, $EmailStub4, $EmailStub5, $EmailStub6, $EmailStub7 -join ' '
 
         Send-MailMessage -To $user.EmailAddress -From $MailSender -SmtpServer $SMTPServer -Subject $Subject -Body $EmailBody
         
         Write-Output $user | add-content C:\PwdLogs\$(get-date -f yyyy-MM-dd)_PwLog_5Days.log
     }
     elseif ($user.PasswordExpiry -eq $ThreeDays) {
         $days = 3
         $EmailBody = $EmailStub1, '"', $user.name, '"', $EmailStub2, $days, $EmailStub3, $ThreeDays, $EmailStub4, $EmailStub5, $EmailStub6, $EmailStub7 -join ' '
 
         Send-MailMessage -To $user.EmailAddress -From $MailSender -SmtpServer $SMTPServer -Subject $Subject -Body $EmailBody
         #Write-Host $user.EmailAddress $MailSender $SMTPServer $Subject $EmailBody
         Write-Output $user | add-content C:\PwdLogs\$(get-date -f yyyy-MM-dd)_PwLog_3Days.log
     }
     elseif ($user.PasswordExpiry -eq $OneDay) {
         $days = 1
         $EmailBody = $EmailStub1, '"', $user.name, '"', $EmailStub2, $days, $EmailStub3, $OneDay, $ChPwdNow, $EmailStub5, $EmailStub6, $EmailStub7 -join ' '
 
         Send-MailMessage -To $user.EmailAddress -From $MailSender -SmtpServer $SMTPServer -Subject $Subject -Body $EmailBody
         #Write-Host $user.EmailAddress $MailSender $SMTPServer $Subject $EmailBody
         Write-Output $user | add-content C:\PwdLogs\$(get-date -f yyyy-MM-dd)_PwLog_1Day.log
         
     }
     }
	 
Get-ChildItem –Path "C:\PwdLogs\" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | Remove-Item
  
