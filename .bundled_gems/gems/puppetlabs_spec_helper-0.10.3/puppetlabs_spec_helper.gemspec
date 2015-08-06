# -*- encoding: utf-8 -*-
$LOAD_PATH.unshift File.expand_path("../lib", __FILE__)
require "puppetlabs_spec_helper/version"

Gem::Specification.new do |s|
  s.name        = "puppetlabs_spec_helper"
  s.version     = PuppetlabsSpecHelper::Version::STRING
  s.authors     = ["Puppet Labs"]
  s.email       = ["modules-dept@puppetlabs.com"]
  s.homepage    = "http://github.com/puppetlabs/puppetlabs_spec_helper"
  s.summary     = "Standard tasks and configuration for module spec tests"
  s.description = "Contains rake tasks and a standard spec_helper for running spec tests on puppet modules"
  s.licenses    = 'Apache-2.0'

  s.files       = `git ls-files`.split("\n")
  s.test_files  = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }

  # Runtime dependencies, but also probably dependencies of requiring projects
  s.add_runtime_dependency 'rake'
  s.add_runtime_dependency 'rspec-puppet'
  s.add_runtime_dependency 'puppet-lint'
  s.add_runtime_dependency 'puppet-syntax'
  s.add_runtime_dependency 'mocha'
end
