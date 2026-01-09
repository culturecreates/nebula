# README

Artsdata Nebula is a website for technical users to view and manage Artsdata datafeeds and Artsdata minted entities.  

Nebula is built ontop of the Artsdata API Plaform. It includes a generic RDF viewer that can render any linked data, not only data from Artsdata. For example, external webpages with structured data can be viewed in Nebula.

This is a 'low code' website with all business logic and data validation rules managed in external data files using [SPARQL](https://www.ontotext.com/knowledgehub/fundamentals/what-is-sparql/) and [SHACL](<https://www.ontotext.com/knowledgehub/fundamentals/what-is-shacl/#:~:text=The%20Shapes%20Constraint%20Language%20(SHACL,data%20instead%20of%20enabling%20inferencing.>).  All tablular views and graph views are generated using SPARQL. All data validation reports and conditions required for minting are generated using SHACL. User athentication is managed with Github.

This website does [content negoitation](https://en.wikipedia.org/wiki/Content_negotiation) and will dereference Artsdata URIs following [linked data](https://en.wikipedia.org/wiki/Linked_data) principles.

This is a work in progress...

If you spot any mistakes please submit pull requests. The home page documentation using markdown is [here](https://github.com/culturecreates/nebula/tree/main/doc). The i18n translations of the user interface can be found [here](https://github.com/culturecreates/nebula/tree/main/config/locales).


# Feature Flags

Features can be turned on/off in the file `/config/initializers/feature_flags.rb`.

There is a feature flag to turn on 'maintenance mode' which will display a message that Artsdata in undergoing maintenance but still allow user access. This can be used in conjunction with other feature flags when working on maintenance, such as turning off minting capabilities.

# Github App
This website is paired with the Github App: 
https://github.com/apps/artsdata-nebula

This app is used to remotely run workflows in other Github repos. For example, the artsdata-planet-x repos that manage data pipelines that crawl websites or use APIs to extract data and publish it to the Artsdata Databus.

Ensure your Github repo has [granted access](https://github.com/organizations/culturecreates/settings/installations/52160418) to the Artsdata Nebula Github App.

# Steps to run locally

  1. clone repo
  1. run `bundle install`
  1. run `rails test`
  1. copy `config/master.key` file from a trusted source (needed to connect to the remote database)
  1. run `rails server`

    To edit credentials:
    `EDITOR="code --wait" rails credentials:edit`

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







