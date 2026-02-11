# Google Analytics Configuration

This application supports Google Analytics (GA4) integration for the kg.artsdata.ca website.

## Setup

The Google Analytics tracking ID can be configured in two ways:

### Option 1: Environment Variable (Recommended for Production)
Set the `GOOGLE_ANALYTICS_ID` environment variable with your GA4 Measurement ID:

```bash
export GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
```

Or add it to your hosting platform's environment configuration.

### Option 2: Rails Credentials
Add the tracking ID to your Rails credentials:

```bash
EDITOR="code --wait" rails credentials:edit
```

Then add:

```yaml
google_analytics_id: G-XXXXXXXXXX
```

## Features

- **Automatic Page View Tracking**: Tracks all page views automatically
- **Turbo Navigation Support**: Properly tracks page changes in single-page app navigation using Turbo
- **Conditional Loading**: Google Analytics script only loads when a tracking ID is configured
- **Security**: Tracking ID is stored securely in credentials or environment variables

## Verification

To verify Google Analytics is working:

1. Set the `GOOGLE_ANALYTICS_ID` environment variable or credential
2. Start the Rails server
3. Open your browser's developer tools and check the Network tab
4. Visit any page on the site
5. You should see requests to `www.googletagmanager.com/gtag/js` and `www.google-analytics.com/g/collect`

## For kg.artsdata.ca

The Google tag for the Nebula stream account should be configured in the production environment.
Contact Suhail@culturecreates.com for the specific Measurement ID for the kg.artsdata.ca stream.
