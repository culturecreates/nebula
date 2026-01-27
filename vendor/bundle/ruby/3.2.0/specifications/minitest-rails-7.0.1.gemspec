# -*- encoding: utf-8 -*-
# stub: minitest-rails 7.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "minitest-rails".freeze
  s.version = "7.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "rubygems_mfa_required" => "true" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mike Moore".freeze]
  s.date = "2023-10-27"
  s.description = "Adds Minitest as the default testing library in Rails".freeze
  s.email = ["mike@blowmage.com".freeze]
  s.homepage = "http://blowmage.com/minitest-rails".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.7.0".freeze)
  s.rubygems_version = "3.4.20".freeze
  s.summary = "Minitest integration for Rails".freeze

  s.installed_by_version = "3.4.20" if s.respond_to? :installed_by_version

  s.specification_version = 4

  s.add_runtime_dependency(%q<minitest>.freeze, ["~> 5.10"])
  s.add_runtime_dependency(%q<railties>.freeze, ["~> 7.0.0"])
  s.add_development_dependency(%q<minitest-autotest>.freeze, ["~> 1.1"])
  s.add_development_dependency(%q<minitest-focus>.freeze, ["~> 1.3"])
  s.add_development_dependency(%q<minitest-rg>.freeze, ["~> 5.2"])
  s.add_development_dependency(%q<rdoc>.freeze, ["~> 6.4"])
  s.add_development_dependency(%q<rubocop>.freeze, ["~> 1.28.0"])
end
