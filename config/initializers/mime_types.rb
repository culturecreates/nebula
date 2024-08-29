Mime::Type.register "application/ld+json", :jsonld
Mime::Type.register "application/star+ld+json", :jsonlds
Mime::Type.register "text/turtle", :ttl
Mime::Type.register "text/star+turtle", :ttls
Mime::Type.register "application/rdf+json", :rdf

# Public files
Rack::Mime::MIME_TYPES[".jsonld"]="application/ld+json"