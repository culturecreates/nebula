# Artsdata Image Policy 
Version 1.0

## How Artsdata manages image information

Artsdata makes various kinds of open data available. These include image URLs: for example, URLs associated with promotional images of events, or images of artist profiles.

Artsdata only collects and stores image URLs; it never stores copies of images on its servers. Artsdata only stores image URLs if those URLs constitute metadata connected to a specific entity, such as an event or artist, for which Artsdata has already obtained permission to extract the data. When a photo credit and a license notice are available at the source, Artsdata extracts this metadata and integrates it inside an image object (“schema:ImageObject”). This process ensures that image metadata can be accessed along with the image URL and the rest of the descriptive metadata about the entity depicted by the image.

### Sample schema:ImageObject

```
"image": {
  "@type": "ImageObject",
  "url": "--URL de l'image : image URL--",
  "usageInfo": "https://kg.artsdata.ca/doc/image-policy",
  "disambiguatingDescription": "--Image de [NOM DE L'ENTITÉ], provenant de [NOM DE DOMAINE DU SITE WEB] : Image of [ENTITY NAME], sourced from [WEBSITE DOMAIN NAME]--",
  "description": "--Alt texte, si disponible : Alt text, if available--",
  "sdDatePublished": "--Date à laquelle les métadonnées de l’ImageObject ont été générées : Date on which the ImageObject’s metadata was generated--"
  },
```

Note: This JSON-LD template is only provided as an exemple. Artsdata’s representation of`ImageObject` may vary from one source to another and may evolve over time. For more information on `ImageObject` modelling, see [this discussion](https://github.com/culturecreates/artsdata-data-model/discussions/137).

## Guidelines for data users

Unless a licence notice indicates otherwise, users must assume that the images whose URLs are stored in Artsdata are copyright protected.

In accordance with standard contractual practice in the industry, with collective agreements, with individual agreements between Artsdata and data providers, as well as with laws applicable in Canada, an image URL should only be used:

- For the same purposes it was originally published or reproduced on the source site; 
- In the same conditions it was originally published or reproduced on the source site; and,
- In accordance with the license notice and/or the terms and conditions of the source site (if applicable).

For example, for a promotional image of a live performance:

- An image URL should only be used in connection with its associated event.
- The user should include enough data about the event to disambiguate it (i.e. make it distinguishable) from similar events.
- When there is available data specifying the event’s official webpage URL (i.e. the event page on the official event organizer’s website) and/or official ticketing platform, the user should include this information, in addition to other data that enables disambiguation from other events.
- If a photo credit and/or other form of attribution information is available (for example, a caption providing the title of the show or the names of performers), it should be used along with the image URL. 

The purpose of this set of conditions is to ensure that the image URL is used in accordance with the intentions of the official organizer who published or reproduced this image (and the right holders who authorized the reproduction of the image).

In doubt, users should consult the source site and obtain authorization for the intended image reuse.

Under no circumstances should an image URL be associated with data or other information that could potentially misrepresent the entity depicted by the image or otherwise mislead other users, human or machine. For example, it is forbidden to use an image URL in such a way as to direct consumers to a reseller’s site or to a fraudulent site, instead of to the official organizer’s website or the official ticketing platform’s website.

## Limitation of liability

In the context of open data, the responsibility of Artsdata administrators (as defined by the Artsdata Community Group, represented by CAPACOA) is limited to making available the image URLs (and associated image metadata), as provided in the data sources. Artsdata offers no guarantee that image URls are accurate, recent or permanent. Artsdata shall not be held responsible for any harm resulting from the use of image URLs by Artsdata users. 

## Infringement reporting

Any use infringing with this policy, with terms and conditions on the source site, and/or with laws applicable in Canada can be reported to Artsdata [via email](artsdata@capacoa.ca).

Further to an infringement report, Arstdata may take the following actions:

- Remove the image URL and the associated metadata from the Artsdata knowledge graph;
- Replace the image URL with another URL so as to detect and trace an infringing use;
- Deny the offender further access to the knowledge graph.

## Consent

By using data from Artsdata, the user consents to this policy.

Users who contravene this policy may be denied access to Artsdata.

[French version](https://kg.artsdata.ca/fr/doc/image-policy)

