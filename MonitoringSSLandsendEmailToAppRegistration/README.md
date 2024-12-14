# SSL Certificate Monitoring Script

This PowerShell script is designed to monitor SSL certificates for a list of URLs provided in an embedded JSON format. It performs the following tasks:

1. **Parameter Setup**: Accepts an optional parameter `$minimumCertAgeDays` to specify the minimum number of days before a certificate is considered close to expiration. The default value is 90 days.

2. **JSON Data Handling**: Converts embedded JSON data into PowerShell objects. The JSON data contains URLs and their renewal types.

3. **DNS and SSL Information Retrieval**:
    - Resolves DNS information for each URL.
    - Retrieves SSL certificate details such as start date, end date, and days until expiration.
    - Checks if the SSL certificate expiration date is within the specified minimum age.

4. **Result Compilation**: Compiles the results into an array of objects containing details like type, origin URL, name, hostnames, IP address, status, SSL start and end dates, days until expiration, and renewal type.

5. **HTML Report Generation**: Generates an HTML report with a modern style, including a summary of the total links analyzed, those expiring soon, and those that are not reachable.

6. **Logic App Integration**: Prepares data for a Logic App and sends the compiled results and HTML report to a specified Logic App URL via a POST request.

7. **Error Handling**: Includes error handling for DNS resolution and SSL certificate retrieval, logging errors and marking the status as 'NOT_OK' for problematic URLs.

