# Puma can serve each request in a thread from an internal thread pool.
# The `threads` method setting takes two numbers: a minimum and maximum.
# Any libraries that use thread pools should be configured to match
# the maximum value specified for Puma. Default is set to 5 threads for minimum
# and maximum; this matches the default thread size of Active Record.
#
max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Specifies the `worker_timeout` threshold that Puma will use to wait before
# terminating a worker in development environments.
#
worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Specifies the `port` that Puma will listen on to receive requests; default is 3000.
#
port ENV.fetch("PORT") { 3000 }

# Specifies the `environment` that Puma will run in.
#
environment ENV.fetch("RAILS_ENV") { "development" }

# Specifies the `pidfile` that Puma will use.
pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Specifies the number of `workers` to boot in clustered mode.
# Workers are forked web server processes. If using threads and workers together
# the concurrency of the application would be max `threads` * `workers`.
# Workers do not work on JRuby or Windows (both of which do not support
# processes).
#
workers ENV.fetch("WEB_CONCURRENCY") { 2 }

# Use the `preload_app!` method when specifying a `workers` number.
# This directive tells Puma to first boot the application and load code
# before forking the application. This takes advantage of Copy On Write
# process behavior so workers use less memory.
#
preload_app!

# preload_app! forks a booted process, so any memoized SPARQL/HTTP client
# built before the fork would have its underlying connection shared across
# worker processes. Drop those memoized clients before/after forking so
# each worker lazily rebuilds its own connection on first use.
before_fork do
  Entity.send(:class_variable_set, :@@artsdata_client, nil) if Entity.class_variable_defined?(:@@artsdata_client)
  Entity.send(:class_variable_set, :@@wikidata_client, nil) if Entity.class_variable_defined?(:@@wikidata_client)
end

on_worker_boot do
  Entity.send(:class_variable_set, :@@artsdata_client, nil) if Entity.class_variable_defined?(:@@artsdata_client)
  Entity.send(:class_variable_set, :@@wikidata_client, nil) if Entity.class_variable_defined?(:@@wikidata_client)
  ArtsdataGraph::SparqlService.instance_variable_set(:@client, nil) if ArtsdataGraph::SparqlService.instance_variable_defined?(:@client)
end

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart
