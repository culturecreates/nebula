Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root "application#home"

  get "test", to: "application#test"

  get "entity", to: "entity#show"
  get "entity/expand", to: "entity#expand"
  get "dereference/card", to: "dereference#card"

  get "github/callback", to: "github#callback"

end
