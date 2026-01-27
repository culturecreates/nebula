# -*- encoding: utf-8 -*-
# stub: rdf-tabular 3.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rdf-tabular".freeze
  s.version = "3.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/rdf-tabular/issues", "documentation_uri" => "https://ruby-rdf.github.io/rdf-tabular", "homepage_uri" => "https://github.com/ruby-rdf/rdf-tabular", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/rdf-tabular" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2023-09-01"
  s.description = "RDF::Tabular processes tabular data with metadata creating RDF or JSON output.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rdf-tabular".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Tabular Data RDF Reader and JSON serializer.".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<bcp47_spec>.freeze, ["~> 0.2"])
  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<rdf-vocab>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<rdf-xsd>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<json-ld>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.8"])
  s.add_development_dependency(%q<nokogiri>.freeze, ["~> 1.15", ">= 1.13.4"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<rspec-its>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<rdf-isomorphic>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-turtle>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<sparql>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<webmock>.freeze, ["~> 3.19"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
