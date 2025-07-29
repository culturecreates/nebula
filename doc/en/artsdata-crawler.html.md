Artsdata-Crawler
=======================

- **Purpose**: Collects publicly available arts and culture data
- **Website**: https://artsdata.ca
- **User-Agent**: `artsdata-crawler (compatible; +https://kg.artsdata.ca/doc/artsdata-crawler)`
- **Behavior**: Respectful crawling with delays between requests
- **Contact**: For questions about this crawler, visit https://artsdata.ca

Permissions
============
To allow the Artsdata crawler to crawl your website, ensure that it is not being blocked. Since there are multiple ways to restrict access to your website, it is important to coordinate with all members of your IT team who manage hosting, including those responsible for servers, firewalls, and web application firewalls.

The Artsdata crawler identifies itself using the User-agent string: ***artsdata-crawler***. To ensure it can crawl your website, avoid blocking this string or any part of it (e.g., "crawler") in your configurations.

The Artsdata crawler also includes a version number appended to the User-agent string. While the version number can be safely ignored, the full User-agent string typically looks like this: artsdata-crawler/1.3.0, where the version may change as the code is updated.

Robots File
============
The primary tool for managing crawler access to your website is the robots.txt file. Ensure that your robots.txt file explicitly allows the Artsdata crawler if necessary.

Here’s how to check and configure robots.txt to allow the Artsdata crawler:

### 1. Locate your robots.txt File

The robots.txt file should be located in the root directory of your website (e.g., https://yourwebsite.com/robots.txt).

### 2. Add a rule

To allow all crawlers (*) or at least add a rule to allow the Artsdata Crawler. For example, add the following lines to the top of your robots.txt file to explicitly allow the Artsdata crawler:

```
User-agent: *
Allow: /
```
OR if you already have other rules to keep...

```
User-agent: artsdata-crawler
Allow: /

...other rules...
```


Either configuration allows the Artsdata crawler to access all pages on your website.


### 3. Save and Upload

Save the updated robots.txt file and upload it to the root directory of your website.

### 4. Test Your Configuration

Use tools like Google Search Console’s Robots Testing Tool or other online robots.txt validators to ensure your configuration is correct. 

You can also do the test using Artsdata.ca described below.

CloudFlare
==========
CloudFlare is a popular web infrastructure and website security company that provides content delivery network (CDN) services, DDoS mitigation, Internet security.

CloudFlare provides several layers of protection that may block the Artsdata crawler. 

To test if your Cloudflare system is blocking the Artsdata crawler, you can disable **Bot Fight Mode** temporarily and test with the method below.

If the test confirms that CloudFlare is blocking the Artsdata crawler please consult with an expert on how to configure CloudFlare to allow the Artsdata crawler to pass.

Testing Access
===============

This test can be used to check if the artsdata-crawler has access to your website.

1. copy the url of an event webpage from on your website
2. go https://kg.artsdata.ca
3. paste your event url into the search box (top right) and click the Search button
4. In the search results page click the option to dereference.
5. If there is a message like ***Forbidden(403)*** or ***Connection reset by peer*** then the artsdata-crawler is still being blocked.





