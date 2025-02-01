using System;
using System.Collections.Generic;
using Azure;
using Azure.Communication.Email;

string connectionString = "endpoint=............................";
var emailClient = new EmailClient(connectionString);


var emailMessage = new EmailMessage(
    senderAddress: "DoNotReply@yourdomain.com",
    content: new EmailContent("Test Email from communication service")
    {
        PlainText = "Hello world via email from visual studio code.",
        Html = @"
		<html>
			<body>
				<h1>Hello world via email from visual studio code..</h1>
			</body>
		</html>"
    },
    recipients: new EmailRecipients(new List<EmailAddress> { new EmailAddress("email@yourtestemail.com") }));
    

EmailSendOperation emailSendOperation = emailClient.Send(
    WaitUntil.Completed,
    emailMessage);
