using System;
using System.Collections.Generic;
using System.IO;
using System.Net.Mime;
using System.Threading.Tasks;
using Azure;
using Azure.Communication.Email;

namespace SendEmail
{
    internal class Program
    {
        static async Task Main(string[] args)
        {
            // This code demonstrates how to fetch your connection string from an environment variable.
            string connectionString = "endpoint=............................................................";
            EmailClient emailClient = new EmailClient(connectionString);

            // Create the email content
            var emailContent = new EmailContent("Newsletter from Achraf Ben Alaya")
            {
                PlainText = "This is the latest news from Achraf Ben Alaya's website.",
                Html = @"
                <html>
                <body>
                    <h1>Latest News from Achraf Ben Alaya</h1>
                    <p>Dear Subscriber,</p>
                    <p>We are excited to share the latest updates from <a href=''>achrafbenalaya.com</a>.</p>
                    <h2>New Features</h2>
                    <ul>
                        <li>Feature 1: Description of feature 1.</li>
                        <li>Feature 2: Description of feature 2.</li>
                        <li>Feature 3: Description of feature 3.</li>
                    </ul>
                    <h2>Upcoming Events</h2>
                    <p>Stay tuned for our upcoming events:</p>
                    <ul>
                        <li>Event 1: Date and details of event 1.</li>
                        <li>Event 2: Date and details of event 2.</li>
                    </ul>
                    <p>Thank you for being a valued subscriber.</p>
                    <p>Best regards,<br/>Achraf Ben Alaya</p>
                </body>
                </html>"
            };

            // Create the To list
            var toRecipients = new List<EmailAddress>
            {
                new EmailAddress("youremail@outlook.com"),
                new EmailAddress("ryle.kutler@finestudio.org"),
            };

            // Create the CC list
            var ccRecipients = new List<EmailAddress>
            {
                new EmailAddress("ripejo9625@bawsny.com"),
            };

            // Create the BCC list
            var bccRecipients = new List<EmailAddress>
            {
                new EmailAddress("wizorvlad@hulas.me"),
            };

            EmailRecipients emailRecipients = new EmailRecipients(toRecipients, ccRecipients, bccRecipients);

            // Create the EmailMessage
            var emailMessage = new EmailMessage(
                senderAddress: "DoNotReply@yyourdomain.com",
                emailRecipients,
                emailContent);

            // Add optional ReplyTo address which is where any replies to the email will go to.
            // emailMessage.ReplyTo.Add(new EmailAddress("<replytoemailalias@emaildomain.com>"));

            // Create the EmailAttachment
            var filePath = @"";
            byte[] bytes = File.ReadAllBytes(filePath);
            var contentBinaryData = new BinaryData(bytes);
            var emailAttachment = new EmailAttachment("image.png", MediaTypeNames.Application.Pdf, contentBinaryData);

            emailMessage.Attachments.Add(emailAttachment);

            try
            {
                EmailSendOperation emailSendOperation = await emailClient.SendAsync(WaitUntil.Completed, emailMessage);
                Console.WriteLine($"Email Sent. Status = {emailSendOperation.Value.Status}");

                // Get the OperationId so that it can be used for tracking the message for troubleshooting
                string operationId = emailSendOperation.Id;
                Console.WriteLine($"Email operation id = {operationId}");
            }
            catch (RequestFailedException ex)
            {
                // OperationID is contained in the exception message and can be used for troubleshooting purposes
                Console.WriteLine($"Email send operation failed with error code: {ex.ErrorCode}, message: {ex.Message}");
            }
        }
    }
}