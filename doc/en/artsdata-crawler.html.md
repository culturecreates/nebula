Artsdata-Crawler
=================

- **Purpose**: The artsdata-crawler collects webpages about arts events, performances, exhibitions, and related activities from publicly available sources, to facilitate discovery and support open cultural data initiatives.
- **Crawling Frequency and Scope**: The crawler accesses webpages periodically (typically daily), mostly restricting itself to calendar and ticketing webpages. It crawls multiple domains relevant to Canadian arts and culture, in several Canadian Provinces.
- **Domain Owner Consent & Crawling Etiquette**: The artsdata-crawler fully respects robots.txt rules and will never crawl a website or URL explicitly disallowed. Additionally, it adheres to crawl-delay directives if specified by a domain owner.
- **Identification**: The artsdata-crawler identifies itself using the following User-Agent string, with a version number that may change over time: `artsdata-crawler/1.3.0 (compatible; +https://kg.artsdata.ca/doc/artsdata-crawler)`
- **Contact**: If you have concerns, questions, or issues related to the artsdata-crawler, please contact us at: <a href="mailto:support@artsdata.ca?subject=artsdata-crawler">support@artsdata.ca</a>

artsdata-crawler does not engage in prohibited activities, such as: 
- Excessive or aggressive data scraping
- Credential stuffing or automated attacks
- Directory traversal or vulnerability scanning
- Scalping, spam, or botnet-related activity


IP Address Management
----------------------

the Artsdata crawler operates exclusively from dedicated, stable IP addresses: [=============== list IP ADDRESSES ===============]

Cloudflare Verification
------------------------

The Artsdata crawler is in the process of being submitted to become a Cloudflare Verified Bot, meeting Cloudflare’s rigorous criteria for transparency, crawling etiquette, and respectful usage.


Permissions management
=======================
To allow the Artsdata crawler to crawl your website, ensure that it is not being blocked. Since there are multiple ways to restrict access to your website, it is important to coordinate with all members of your IT team who manage hosting, including those responsible for servers, firewalls, and web application firewalls.

In your configurations, avoid blocking the identification string (`artsdata-crawler/1.3.0 (compatible; +https://kg.artsdata.ca/doc/artsdata-crawler)`) in whole or in part (e.g., "crawler").

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

Either configuration allows the Artsdata crawler to access pages on your website.


### 3. Save and Upload

Save the updated robots.txt file and upload it to the root directory of your website.

### 4. Test Your Configuration

Use tools like Google Search Console’s Robots Testing Tool or other online robots.txt validators to ensure your configuration is correct. 

You can also use the following test using Artsdata.ca.

Testing Access using Artsdata.ca
=================================

To verify if the artsdata-crawler has access to your website:

* Copy an event webpage URL from your website.
* Visit https://kg.artsdata.ca.
* Paste your URL into the search box at the top right and click Search.
* On the results page, click "Dereference."

If you see errors like "Forbidden (403)" or "Connection reset by peer," then the crawler is still blocked.

CloudFlare
===========

CloudFlare is a popular web infrastructure and website security company that provides content delivery network (CDN) services, DDoS mitigation, Internet security.

CloudFlare provides several layers of protection that may block the Artsdata crawler. 

To test if your Cloudflare system is blocking the Artsdata crawler, you can disable **Bot Fight Mode** temporarily and test with the method below.

If the test confirms that CloudFlare is blocking the Artsdata crawler please consult with an expert on how to configure CloudFlare to allow the Artsdata crawler to pass.



