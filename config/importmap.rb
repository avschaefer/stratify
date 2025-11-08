# Pin npm packages by running ./bin/importmap

pin "application", preload: true
pin "@hotwired/turbo-rails", to: "https://cdn.jsdelivr.net/npm/@hotwired/turbo-rails@8.0.4/dist/turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus@3.2.2/dist/stimulus.min.js", preload: true
pin "@hotwired/stimulus-loading", to: "https://cdn.jsdelivr.net/npm/@hotwired/stimulus-loading@1.2.1/dist/stimulus-loading.js", preload: true
pin_all_from "app/javascript/controllers", under: "controllers"
