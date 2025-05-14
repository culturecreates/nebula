Artsdata Google Smart-Chip
===================
A Google Workspace add-on that detects [Artsdata URIs](https://culturecreates.github.io/artsdata-data-model/identifier-recommendations.html#about-the-artsdata-identifier) in Google sheets and displays a preview about the linked event, people, place or organization entities. 

The add-on reads URLs in Google sheets and dectects those that match the Artsdata URI format. When the user hovers over the link, a preview card is displayed with additional information about the entity.

![image](https://github.com/user-attachments/assets/c0d27d6e-2bb9-419b-8725-6796630ac48b)

**Note :** The _"Replace URL with its title?"_ feature is not recommended with Google Sheet that are intended for upload to Artsdata. Artsdata's Google Sheets Extract-Transform-Load workflow only reads the actual cell values; not hyperlinks. Replacing your Artsdata URIs by their title will override your URIs and make them no longer readable by Artsdata.

- [More information about Google Sheets uploads](https://culturecreates.github.io/artsdata-data-model/architecture/google-sheets.html)
- [Technical documentation about Google's Smart Chips](https://developers.google.com/workspace/add-ons/guides/preview-links-smart-chips)

Terms of Service
-----------------
By using the Artsdata Google Smart-Chip add-on, you agree to the following terms:

1. **Usage**: The add-on is provided as-is and is intended for detecting Artsdata URIs in Google Sheets and displaying previews. Any misuse or unauthorized modification of the add-on is prohibited.
2. **Data Handling**: The add-on reads URLs within your Google Sheets for the sole purpose of detecting and processing those that match the Artsdata URI format. No other data is ever transmitted outside of your Google Workspace environment.
3. **Liability**: Artsdata is not responsible for any inaccuracies in the information displayed or any issues arising from the use of the add-on, including any accidental or intentional replacing of URIs by the entities' names (see the note below).
4. **Support**: Users can contact support for assistance (see the "How users can get help" section below).
5. **Updates**: The add-on may be updated periodically to improve functionality or address issues. Continued use of the add-on constitutes acceptance of these updates.
6. **Termination**: Artsdata reserves the right to terminate access to the add-on at any time for any reason.

By using this add-on, you acknowledge that you have read and understood these terms.


Privacy Policy
--------------
The Artsdata Google Smart-Chip add-on respects your privacy and is designed to handle your data securely. By using this add-on, you agree to the following privacy practices:

1. **Data Processing**: The add-on processes URLs within your Google Sheets to provide additional information about events, people, places, and organizations. This processing occurs entirely within your Google Workspace environment.
2. **Data Storage**: No data is stored outside of your Google Workspace environment. The add-on does not retain or share any information processed during its use.
3. **Third-Party Services**: The add-on does not integrate with or share data with any third-party services.
4. **User Control**: You retain full control over your data. The add-on functions essentially in read-only mode. It only edits the Google Sheet if the user chooses to take use the _"Replace URL with its title?"_ Google Smart Chip feature.
6. **Security**: The add-on is designed to operate within the secure environment of Google Workspace, adhering to its security and privacy standards.
7. **Changes to Privacy Policy**: Artsdata reserves the right to update this privacy policy at any time. Continued use of the add-on constitutes acceptance of any changes.

If you have any questions or concerns about this privacy policy, please contact support (see the "How users can get help" section below).


How users can get help
-----------------
If you need assistance with the Artsdata Google Smart-Chip add-on, the Artsdata Stewards are here to help. You can reach out to them for support, feedback, or any questions related to the add-on.

For support, please contact us via email at **support@artsdata.ca**. We aim to respond to all inquiries within 2-3 business days.
