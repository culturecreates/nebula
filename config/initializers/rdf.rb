# RDF::Term#to_ntriples (used by app/views/application/_statement_objects.html.erb
# to round-trip a triple's subject/predicate/object through a hidden field) is
# defined by rdf/ntriples, which the base rdf gem does not require automatically.
# Without this, whether the method exists depends on some other code path
# happening to load it first, causing an intermittent NoMethodError.
require 'rdf/ntriples'
