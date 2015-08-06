# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "puppet-syntax"
  s.version = "2.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dan Carley"]
  s.date = "2015-02-26"
  s.description = "Syntax checks for Puppet manifests and templates"
  s.email = ["dan.carley@gmail.com"]
  s.homepage = "https://github.com/gds-operations/puppet-syntax"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Syntax checks for Puppet manifests, templates, and Hiera YAML"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<gem_publisher>, ["~> 1.3"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<gem_publisher>, ["~> 1.3"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<gem_publisher>, ["~> 1.3"])
  end
end
