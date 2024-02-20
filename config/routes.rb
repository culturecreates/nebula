Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "application#home"

  get "test", to: "application#test"

  get "entity", to: "entity#show"
  get "entity/unsupported_claims", to: "entity#unsupported_claims"
  get "entity/derived_statements", to: "entity#derived_statements"
  get "entity/expand", to: "entity#expand"
  get "dereference/card", to: "dereference#card"
  get "dereference/external", to: "dereference#external"
  get "github/callback", to: "github#callback"
  get "query/show", to: "query#show"
  get "mint/preview", to: "mint#preview"
  get "mint/link", to: "mint#link"
  get "reconcile/query", to: "reconcile#query"

  get '/sparql', to: redirect('http://artsdata-trifid-production.herokuapp.com/sparql/')

end
