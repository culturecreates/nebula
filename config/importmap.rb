# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.3/dist/js/bootstrap.esm.js"
# pin "bootstrap", to: "bootstrap.js" # @5.3.3
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/lib/index.js"
# pin "@popperjs/core", to: "@popperjs--core.js" # @2.11.8
pin "@stimulus-components/clipboard", to: "@stimulus-components--clipboard.js" # @5.0.0
