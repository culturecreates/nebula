# -*- encoding: utf-8 -*-
# stub: rdf-trix 3.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rdf-trix".freeze
  s.version = "3.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/rdf-trix/issues", "documentation_uri" => "https://ruby-rdf.github.io/rdf-trix", "homepage_uri" => "https://github.com/ruby-rdf/rdf-trix", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/rdf-trix" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Arto Bendiken".freeze]
  s.date = "2023-08-26"
  s.description = "RDF.rb extension for parsing/serializing TriX data.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rdf-trix".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "TriX support for RDF.rb.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<rdf-xsd>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-trig>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-ordered-repo>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.15", ">= 1.15.4"])
  s.add_development_dependency(%q<libxml-ruby>.freeze, ["~> 4.1"])
end
