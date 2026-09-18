# README

Artsdata Nebula is a website for technical users to view and manage Artsdata datafeeds and Artsdata minted entities.  

Nebula is built ontop of the Artsdata API Plaform. It includes a generic RDF viewer that can render any linked data, not only data from Artsdata. For example, external webpages with structured data can be viewed in Nebula.

This is a 'low code' website with all business logic and data validation rules managed in external data files using [SPARQL](https://www.ontotext.com/knowledgehub/fundamentals/what-is-sparql/) and [SHACL](<https://www.ontotext.com/knowledgehub/fundamentals/what-is-shacl/#:~:text=The%20Shapes%20Constraint%20Language%20(SHACL,data%20instead%20of%20enabling%20inferencing.>).  All tablular views and graph views are generated using SPARQL. All data validation reports and conditions required for minting are generated using SHACL. User athentication is managed with Github.

This website does [content negotiation](https://en.wikipedia.org/wiki/Content_negotiation) and will dereference Artsdata URIs following [linked data](https://en.wikipedia.org/wiki/Linked_data) principles.

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

# Heroku Production Configuration

Production runs on 2 Standard-2X dynos (1024MB RAM each), configured with:

- `WEB_CONCURRENCY=1` — one Puma worker process per dyno
- `RAILS_MAX_THREADS=10` — Puma's per-worker thread pool
- `MALLOC_ARENA_MAX=2` — caps glibc malloc arenas, reducing memory fragmentation from Puma's threads

**Why one worker per dyno, not two:** `config/puma.rb` uses `preload_app!` to share memory between forked workers via copy-on-write, but in practice 2 workers left only ~100MB of headroom under the 1024MB dyno quota. When tested under heavy load the app sat there continuously tripping Heroku's `R14 (Memory quota exceeded)`.

Dropping to 1 worker per dyno (with `RAILS_MAX_THREADS` raised from 3 to 10 to keep total in-flight request capacity comparable) brought steady-state memory down to ~650-900MB per dyno with real headroom, and extended monitoring after the change showed no `R14` recurrence.

**Why `MALLOC_ARENA_MAX=2`:** glibc's default `malloc` gives each thread its own memory "arena" (up to 8 × the number of CPU cores) so concurrent threads don't contend on the same allocator lock. That's a reasonable tradeoff for a C program, but Ruby's own GC already does most of the work of managing object memory, so paying for many separate glibc arenas on top of that mostly buys fragmentation: each arena keeps its own free list and can hold onto pages it's freed without returning them to the OS or letting another arena reuse them, so measured process RSS can run well above what's actually reachable/live. With `RAILS_MAX_THREADS=10`, an uncapped worker could spin up several arenas, each fragmenting independently — directly working against the memory headroom this section is trying to protect. Setting `MALLOC_ARENA_MAX=2` caps glibc to 2 arenas per process, trading a small amount of allocator lock contention (threads occasionally waiting on each other to allocate) for meaningfully lower memory overhead. This is a well-known tuning knob for any multi-threaded Ruby server (Puma, Sidekiq, etc.) on glibc-based systems like Heroku's.

**Why 2 dynos, not 1 bigger one:** redundancy. With one worker per dyno, if that single worker hangs, Heroku's router still has a second, fully independent dyno to route to while Puma's cluster monitor restarts the stuck one. Scaling this app for more capacity should mean adding another dyno (`heroku ps:scale web=N`), not raising `WEB_CONCURRENCY` back up — see the memory analysis above for why that doesn't pay off on this workload. A Performance-tier dyno with dedicated cores and more headroom could change this calculus, but that hasn't been tested.

# Steps to run locally

  1. clone repo
  1. run `bundle install`
  1. run `rails test`
  1. copy `config/master.key` file from a trusted source (needed to connect to the remote database)
  1. run `rails server`

    To edit credentials:
    `EDITOR="code --wait" rails credentials:edit`

    To rebuild assets:
    `rails assets:precompile`

## No Node.js / JS build step

This app has no JS build step at all — Bootstrap/Stimulus JS are pinned via
`importmap-rails`, and CSS is compiled with `sassc-rails` (libsass, a C
extension via `ffi`), not a JS-based Sass compiler. There's deliberately no
`bootstrap` Ruby gem either: it pulls in `autoprefixer-rails`/`execjs`,
which needs a Node.js runtime to run at asset-compile time, causing
Heroku's `heroku/ruby` buildpack to silently install (and periodically
drift) a default Node version. Since this app applies zero Sass-level
customization to Bootstrap, `app/assets/stylesheets/bootstrap.min.css` is
instead a vendored, prebuilt Bootstrap CSS file, loaded directly in the
layout — same styling, no Node dependency, one less runtime to install to
clone and run this app locally.

If a future change needs the `bootstrap` gem again (e.g. to override Sass
variables), re-adding it will reintroduce the Node/execjs requirement; pin
the Node version via `package.json`'s `engines.node` field **and** add the
`heroku/nodejs` buildpack ahead of `heroku/ruby`
(`heroku buildpacks:add heroku/nodejs --index 1`) if so, since `heroku/ruby`
alone ignores that field.

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







