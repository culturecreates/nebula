# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration
  Steps from scratch:
  ```
  # create Rails 7 App
  rails new nebula

  # set rvm config of ruby
  echo "rvm use 3.1.2@nebula --create" > nebula/.rvmrc
  cd nebula

  # pin Bootstrap Using Importmap-Rails
  ./bin/importmap pin bootstrap@5.1.3
  ./bin/importmap pin @popperjs/core@2.11.2

  Check [blog](https://jasonfleetwoodboldt.com/courses/rails-7-crash-course/rails-7-importmap-rails-with-bootstrap-stimulus-turbo-long-tutorial/) for troubleshooting 

  ```

  To edit credentials:
  `EDITOR="code --wait" rails credentials:edit`

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...
