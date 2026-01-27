# -*- encoding: utf-8 -*-
# stub: rdf-reasoner 0.9.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rdf-reasoner".freeze
  s.version = "0.9.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/ruby-rdf/rdf-reasoner/issues", "documentation_uri" => "https://ruby-rdf.github.io/rdf-reasoner", "homepage_uri" => "https://github.com/ruby-rdf/rdf-reasoner", "mailing_list_uri" => "https://lists.w3.org/Archives/Public/public-rdf-ruby/", "source_code_uri" => "https://github.com/ruby-rdf/rdf-reasoner" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregg Kellogg".freeze]
  s.date = "2023-08-26"
  s.description = "Reasons over RDFS/OWL vocabularies to generate statements which are entailed based on base RDFS/OWL rules along with vocabulary information. It can also be used to ask specific questions, such as if a given object is consistent with the vocabulary ruleset. This can be used to implement SPARQL Entailment Regimes.".freeze
  s.email = "public-rdf-ruby@w3.org".freeze
  s.homepage = "https://github.com/ruby-rdf/rdf-reasoner".freeze
  s.licenses = ["Unlicense".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 3.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "RDFS/OWL Reasoner for RDF.rb".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<rdf>.freeze, ["~> 3.3"])
  s.add_runtime_dependency(%q<rdf-xsd>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-spec>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-vocab>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<rdf-turtle>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<json-ld>.freeze, ["~> 3.3"])
  s.add_development_dependency(%q<equivalent-xml>.freeze, ["~> 0.6"])
  s.add_development_dependency(%q<rspec>.freeze, ["~> 3.12"])
  s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
end
