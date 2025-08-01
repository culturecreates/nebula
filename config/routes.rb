Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
    # Defines the root path route ("/")
    root "application#home"

    get "test", to: "application#test"
    get "entity", to: "entity#show"
    get "entity/unsupported_claims", to: "entity#unsupported_claims"
    get "entity/derived_statements", to: "entity#derived_statements"
    get "entity/expand", to: "entity#expand"
    get "dereference/card", to: "dereference#card"
    get "dereference/external", to: "dereference#external"
    get "query/show", to: "query#show"
    get "mint/preview", to: "mint#preview"
    post "mint/link", to: "mint#link"
    post "mint/link_facts", to: "mint#link_facts"
    get "mint/wikidata", to: "mint#wikidata"
    get "reconcile/query", to: "reconcile#query"
    get "reconcile/batch", to: "reconcile#batch"
    get "validate/wikidata", to: "validate#wikidata"
    get "validate", to: "validate#show"


    resources :artifact do 
      collection do
        post :push_latest,  :toggle_auto_minting
      end
    end

    resources :ical
    resources :sparql_manager

    get "logout", to: "github#logout!"
    
    match "doc/*path", to: "application#doc", via: :get
    
  end

  # Support legacy urls to Zazuko YASGUI SPARQL UI
  get 'sparql', to: redirect('http://artsdata-trifid-production.herokuapp.com/sparql/', status: 307)

  # Github OAuth
  get "github/callback", to: "github#callback"
  get "github/workflows", to: "github#workflows"
  get "github/sparqls", to: "github#sparqls"

  # Footlight Aggregator
  get "footlight/export", to: "footlight#export"

  # The following URI paths are dereferencable and handled by the ResourceController
  match "resource/*path", to: "resource#show", via: :get
  match "databus/*path", to: "resource#show", via: :get
  match "shacl/*path", to: "resource#show", via: :get
  match "ontology/*path", to: "resource#show", via: :get
  match "minted/*path", to: "resource#show", via: :get
  match "culture-creates/*path", to: "resource#show", via: :get ## TODO: Move towards a prefix graph/*path
  match "core/*path", to: "resource#show", via: :get ## TODO: Should use graph/core and remove this line? 

end
