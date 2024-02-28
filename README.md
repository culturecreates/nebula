# README

Pre-alpha of Artsdata Nebula. Work in progress...

* Configuration
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

  Github App:
  https://github.com/organizations/culturecreates/settings/apps/artsdata-nebula

