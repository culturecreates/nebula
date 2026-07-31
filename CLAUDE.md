# CLAUDE.md

Guidance for Claude Code (and other devs) working in this repo.

## What this app is

Artsdata Nebula is a Rails 7 website for viewing and managing linked data (RDF)
on the Artsdata Knowledge Graph. It's a generic RDF viewer/editor: it can
dereference and render *any* linked data, not just Artsdata's own entities.

Key idea: this is a **"low code" app**. Business logic and data validation
live in external **SPARQL** and **SHACL** files under `app/services/sparqls/`
and `app/services/shacls/`, not in Ruby. Controllers mostly load a SPARQL
query, run it against the triplestore, and hand the result graph to a view.
When changing behavior, look for a `.sparql`/`.ttl` file before assuming
logic is in Ruby.

## Architecture

- **No database / no ActiveRecord.** `config/application.rb` explicitly
  requires Rails components but not `active_record/railtie`. There are only
  two real "models": [Entity](app/models/entity.rb) and
  [Artifact](app/models/artifact.rb), both plain Ruby objects wrapping an
  `RDF::Graph`. All persistent data lives in a remote **GraphDB** triplestore,
  queried over SPARQL.
- **Data access**: [ArtsdataGraph::SparqlService](app/services/artsdata_graph/sparql_service.rb)
  builds a `SPARQL::Client` pointed at
  `Rails.application.config.graph_api_endpoint` + `/repositories/#{graph_repository}`.
  Writes use HTTP Basic auth (`graph_db_basic_auth` credential) against the
  `/statements` endpoint. `graph_api_endpoint` differs per environment (see
  `config/environments/*.rb`): local GraphDB on `localhost:7200` in dev,
  `staging-db.artsdata.ca` in test/staging, `db.artsdata.ca` in production.
- **SPARQL query files**: [app/services/sparqls/](app/services/sparqls/) — `.sparql`
  files, often namespaced in subfolders by controller (e.g.
  `sparqls/reconcile_controller/`, `sparqls/query_controller/`). Loaded via
  [SparqlLoader](app/services/sparql_loader.rb), which also supports loading
  a SPARQL file from a remote URL (e.g. a GitHub-hosted query) and doing
  simple string substitution before execution.
- **Content negotiation / dereferencing**: Nebula follows linked-data
  conventions — the same entity URI can return HTML, Turtle, Turtle-star,
  JSON-LD, JSON-LD-star, or RDF/XML depending on `Accept` header or format
  extension. See `EntityController#show`'s `respond_to` block and
  [ResourceController](app/controllers/resource_controller.rb) (handles
  `/resource/*`, `/databus/*`, `/shacl/*`, `/ontology/*`, `/minted/*`,
  `/core/*` — redirects to the right `entity` format based on `Accept`).
- **Frontend**: Hotwire (Turbo + Stimulus) via `turbo-rails`/`stimulus-rails`,
  `importmap-rails` (no webpack/node build), Bootstrap 5. Stimulus controllers
  live in [app/javascript/controllers/](app/javascript/controllers/).
- **Auth**: GitHub OAuth (GitHub App), session-based — see
  [GithubController](app/controllers/github_controller.rb). No `User` model;
  identity/roles live entirely in the session (`session[:handle]`,
  `session[:teams]`, `session[:accounts]`) populated from the GitHub API
  after OAuth callback.
- **RBAC**: role checks are keyed off GitHub **team IDs**, not app-level
  roles. See `user_has_access?` / `ensure_access` in
  [ApplicationController](app/controllers/application_controller.rb):
  Level 2 = team `10808270` (Artsdata Admins), Level 1 = team `10808293`
  (Artsdata Editors). Controllers gate actions with
  `before_action :ensure_access, only: [...]` calling `ensure_access("feature_name")`,
  which also checks a matching `feature_#{name}_enabled` config flag.
- **Feature flags**: [config/initializers/feature_flags.rb](config/initializers/feature_flags.rb) —
  plain booleans on `Rails.application.config` (e.g.
  `feature_minting_enabled`, `feature_delete_entity_enabled`,
  `feature_maintenance_mode_enabled`). Also drives a homepage announcement
  banner (`announcement_enabled`/`announcement_message`).
- **External Artsdata services**: reconciliation, minting, and linking are
  separate HTTP APIs (not in this repo), configured per-environment as
  `artsdata_recon_endpoint`, `artsdata_mint_endpoint`, `artsdata_link_endpoint`,
  `artsdata_databus_endpoint`, `artsdata_maintenance_endpoint`. See
  [MintController](app/controllers/mint_controller.rb),
  [ReconcileController](app/controllers/reconcile_controller.rb).
- **GitHub App integration**: beyond OAuth login, Nebula uses a GitHub App
  (https://github.com/apps/artsdata-nebula) to remotely trigger GitHub Actions
  workflows in *other* repos (e.g. `artsdata-planet-x` data-pipeline repos)
  that crawl/import data onto the Artsdata Databus. A repo must grant the app
  access before Nebula can trigger its workflows.

## Notable controllers

- `EntityController` — show/delete entities and individual statements
  (triples), including "inverted" triples (object of the entity rather than
  subject), unsupported/derived claims, property claims.
- `ResourceController` — dereferences `/resource`, `/databus`, `/shacl`,
  `/ontology`, `/minted`, `/core` paths via content negotiation.
- `MintController` / `ReconcileController` — mint new Artsdata URIs,
  reconcile external entities against Artsdata via the external recon/mint/link APIs.
- `SparqlManagerController` / `QueryController` — run/manage stored SPARQL
  queries against the graph.
- `GithubController` — OAuth callback/login, listing workflows, listing
  stored SPARQL queries from a GitHub-hosted repo.

## Gotcha: Turbo Stream requests + implicit rendering

Turbo appends `text/vnd.turbo-stream.html` to the `Accept` header on *every*
fetch it manages, including the GET that follows a server redirect after a
Turbo Stream form submission (e.g. a `delete_button_to`). If a controller
action's `respond_to` block has a catch-all branch (`format.all`, `format.any`)
that never calls `render` explicitly, Rails' implicit renderer will try to
find a template for whatever format was negotiated — which may be
`turbo_stream` even though only an `.html.erb` template exists — and raise
`ActionController::UnknownFormat` (406). If you add more turbo_stream-driven
actions, either add a real `.turbo_stream.erb` template or force
`render "show", formats: [:html]` in the catch-all branch, as
`EntityController#show` does.

## Running locally

1. `bundle install`
2. Copy `config/master.key` from a trusted source (needed for
   `graph_db_basic_auth` and other credentials to reach the real graph DB).
3. `rails server`

To edit encrypted credentials: `EDITOR="code --wait" rails credentials:edit`

## Testing

This repo uses **Minitest** (`minitest-rails`, `capybara`, `webmock`,
`mocha`, `vcr`) with tests under `test/` (`test/controllers/`,
`test/models/`, `test/lib/`, plus `test/vcr_cassettes/` for recorded HTTP
interactions) — there is no `spec/`/RSpec.

Local Ruby is managed via **rvm** with gemset `ruby-3.1.2@nebula`. If the
active Ruby/gemset doesn't match, `bin/rails test` fails with
`Bundler::GemNotFound`. Run tests with:

```
source ~/.rvm/scripts/rvm
rvm use ruby-3.1.2@nebula
bundle exec rails test                                   # full suite
bundle exec rails test test/controllers/entity_controller_test.rb  # one file
```

Note: `ensure_access` (the RBAC gate) short-circuits and always passes when
`Rails.env.test?`, so controller tests don't need to fake GitHub sessions to
exercise access-gated actions.
