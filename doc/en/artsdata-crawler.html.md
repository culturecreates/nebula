Artsdata-Crawler Permission
=======================

To allow the Artsdata crawler to crawl your website, ensure that it is not being blocked. Since there are multiple ways to restrict access to your website, it is important to coordinate with all members of your IT team who manage hosting, including those responsible for servers, firewalls, and web application firewalls.

The Artsdata crawler identifies itself using the User-agent string: artsdata-crawler. To ensure it can crawl your website, avoid blocking this string or any part of it (e.g., "crawler") in your configurations.

The Artsdata crawler also includes a version number appended to the User-agent string. While the version number can be safely ignored, the full User-agent string typically looks like this: artsdata-crawler/1.3.0, where the version may change as the code is updated.

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

You can also do a test by:

1. copy a url with an event on your website
2. go https://kg.artsdata.ca
3. paste your event url into the search box (top right) and click the Search button
4. In the search results page click the option to dereference.
5. If there is a message saying ***Could not detect structured data. Connection reset by peer. The destination may be blocking user-agent: 'artsdata-crawler'*** then the artsdata-crawler is still being blocked.


