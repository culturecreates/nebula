# RDF::Term#to_ntriples lives in rdf/ntriples, which the base rdf gem doesn't
# load on its own. Require it eagerly: controllers, helpers and views call
# to_ntriples without necessarily having autoloaded Entity first.
require 'rdf/ntriples'
