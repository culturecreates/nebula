# README

Artsdata Nebula is a website for technical users to view and manage Artsdata datafeeds and Artsdata minted entities.  

Nebula is built ontop of the Artsdata API Plaform. It includes a generic RDF viewer that can render any linked data, not only data from Artsdata. For example, external webpages with structured data can be viewed in Nebula.

This is a 'low code' website with all business logic and data validation rules managed in external data files using [SPARQL](https://www.ontotext.com/knowledgehub/fundamentals/what-is-sparql/) and [SHACL](<https://www.ontotext.com/knowledgehub/fundamentals/what-is-shacl/#:~:text=The%20Shapes%20Constraint%20Language%20(SHACL,data%20instead%20of%20enabling%20inferencing.>).  All tablular views and graph views are generated using SPARQL. All data validation reports and conditions required for minting are generated using SHACL. User athentication is managed with Github.

This website does [content negoitation](https://en.wikipedia.org/wiki/Content_negotiation) and will dereference Artsdata URIs following [linked data](https://en.wikipedia.org/wiki/Linked_data) principles.

This is a work in progress...

If you spot any mistakes please submit pull requests. The home page documentation using markdown is [here](https://github.com/culturecreates/nebula/tree/main/doc). The i18n translations of the user interface can be found [here](https://github.com/culturecreates/nebula/tree/main/config/locales).

This website is paired with the Github App:
  https://github.com/apps/artsdata-nebula


# Configuration

## Supported HTTPs domains

The subdomain for this website is kg.artsdata.ca.

The naked domain http://artsdata.ca is redirected to https://kg.artsdata.ca

GoDaddy does NOT support HTTPS forwarding for domains, so https://artsdata.ca will NOT work until we find a better DNS host that offers ANAME/ALIAS functionality. 

## Rails 7 Setup
  Steps from scratch:
  ```
  # create Rails 7 App
  rails new nebula

  # set rvm config of ruby
  echo "rvm use 3.1.2@nebula --create" > nebula/.rvmrc
  cd nebula

  # pin Bootstrap Using Importmap-Rails
  ./bin/importmap pin bootstrap@5.3.2
  ./bin/importmap pin @popperjs/core@2.11.8

  Check [blog](https://jasonfleetwoodboldt.com/courses/rails-7-crash-course/rails-7-importmap-rails-with-bootstrap-stimulus-turbo-long-tutorial/) for troubleshooting 

  ```

  To edit credentials:
  `EDITOR="code --wait" rails credentials:edit`


# Github App

https://github.com/apps/artsdata-nebula

