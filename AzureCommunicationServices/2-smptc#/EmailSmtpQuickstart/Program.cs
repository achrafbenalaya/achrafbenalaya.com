using System.Net;
using System.Net.Mail;

string smtpAuthUsername = "";
string smtpAuthPassword = "";
string sender = "";
string recipient = "";
string subject = "Welcome to Azure Communication Service Email SMTP";
string body = "This email message is sent from Azure Communication Service Email using SMTP.";

string smtpHostUrl = "smtp.azurecomm.net";
var client = new SmtpClient(smtpHostUrl)
{
    Port = 587,
    Credentials = new NetworkCredential(smtpAuthUsername, smtpAuthPassword),
    EnableSsl = true
};

var message = new MailMessage(sender, recipient, subject, body);

try
{
    client.Send(message);
    Console.WriteLine("The email was successfully sent using Smtp.");
}
catch (Exception ex)
{
    Console.WriteLine($"Smtp send failed with the exception: {ex.Message}.");
}