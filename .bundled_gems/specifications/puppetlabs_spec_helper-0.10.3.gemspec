# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "puppetlabs_spec_helper"
  s.version = "0.10.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Puppet Labs"]
  s.date = "2015-05-11"
  s.description = "Contains rake tasks and a standard spec_helper for running spec tests on puppet modules"
  s.email = ["modules-dept@puppetlabs.com"]
  s.homepage = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  s.licenses = ["Apache-2.0"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "Standard tasks and configuration for module spec tests"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>, [">= 0"])
      s.add_runtime_dependency(%q<rspec-puppet>, [">= 0"])
      s.add_runtime_dependency(%q<puppet-lint>, [">= 0"])
      s.add_runtime_dependency(%q<puppet-syntax>, [">= 0"])
      s.add_runtime_dependency(%q<mocha>, [">= 0"])
    else
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<rspec-puppet>, [">= 0"])
      s.add_dependency(%q<puppet-lint>, [">= 0"])
      s.add_dependency(%q<puppet-syntax>, [">= 0"])
      s.add_dependency(%q<mocha>, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<rspec-puppet>, [">= 0"])
    s.add_dependency(%q<puppet-lint>, [">= 0"])
    s.add_dependency(%q<puppet-syntax>, [">= 0"])
    s.add_dependency(%q<mocha>, [">= 0"])
  end
end
