# Data Contributor Conditions

_Version 1.0_

Sharing data via the Artsdata knowledge graph involves a large number of data transformation, enrichment and enhancement processes. These processes are mostly invisible to data contributors, but are nevertheless essential to realize the full potential benefits of linked open data. This page provides an overview of the main processes known as extraction-transformation-loading (ETL).

The Contributor who agrees to provide data to the Artsdata knowledge graph authorizes Artsdata staff<sup>1</sup> to perform the following data extraction-transformation-loading (ETL) activities:

- Extract data using the most appropriate technological option, according to the Contributor's circumstances (see the list of [extraction methods](https://culturecreates.github.io/artsdata-data-model/architecture/overview.html#data-providers)).
- Transform this data into RDF format, according to the [Artsdata data model](https://culturecreates.github.io/artsdata-data-model/index.html) (which is 100% compliant with Google recommendations).
- Store the extracted and transformed data in a graph database instance dedicated to the Contributor's data (hereinafter referred to as the “source graph”) and in the [list of Artsdata data providers](https://kg.artsdata.ca/query/show?sparql=feeds_all&title=Data+Feeds). 
- Make the Contributor's data available to data consumers via the SPARQL terminal and Artsdata APIs under a [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/deed) license and/or other copyleft licenses utilized by the Contributor.
- Generate and publish administrative metadata for traceability, indicating the Contributor as the source of the data.
- Assign scores to source graphs according to their level of authority, reliability and exhaustivity.
- Assign Artsdata IDs to the main entities in the Contributor's data, if they have not already been assigned one; or else, link the main entities to their Artsdata ID, if one already exists.
- Copy the data, in whole or in part, to the Artsdata core graph and adapt it, notably by combining it with data from other source graphs.
- Preserve data in the core graph, even when the entity to which the data refers is no longer available in the source graph (for example, preserving data from a past event).
- Perform various semantic data enrichment activities, in the source graph and/or core graph, such as :
  - Detecting and correcting minor data syntax errors;
  - Detecting the timezone of a location and assigning a timezone identifier to that location;
  - Adding the date/time or timezone if it is missing, or modifying it if it is incorrect;
  - Transforming image URLs into schema:ImageObject entities, in accordance with the [Artsdata image policy](https://kg.artsdata.ca/doc/image-policy);  
  - Linking identifiable secondary entities (for example, people, organizations or places) to existing [persistent identifiers](https://culturecreates.github.io/artsdata-data-model/identifier-recommendations.html) (Artsdata ID, Wikidata ID, ISNI);
  - Integrate additional data points retrieved via persistent identifiers.  

Data loaded into Artsdata is enhanced by [Artsdata data consumers](https://kg.artsdata.ca/doc/data-consumers). It can also be indexed, read, copied and/or stored by search engines and other third parties, as authorized by the [CC0 1.0 Universal](https://creativecommons.org/publicdomain/zero/1.0/deed) license.

Artsdata provides no warranty and assumes no liability with respect to the use of data uploaded to the Artsdata knowledge graph.


For any questions regarding these conditions, please contact the Artsdata team at artsdata@capacoa.ca.

<sup>1</sup> _Artsdata staff_ refers to the staff of CAPACOA, Culture Creates and/or any other third party authorized to contribute to the stewardship of the Artsdata knowledge graph.
