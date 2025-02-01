$Password = ConvertTo-SecureString -AsPlainText -Force -String ''
$Cred = New-Object -TypeName PSCredential -ArgumentList '', $Password
Send-MailMessage -From 'DoNotReply@yourdomain.com' -To '' -Subject 'Test mail' -Body 'test' -SmtpServer 'smtp.azurecomm.net' -Port 587 -Credential $Cred -UseSsl