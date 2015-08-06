# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rspec-puppet"
  s.version = "2.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Tim Sharpe"]
  s.date = "2015-03-13"
  s.description = "RSpec tests for your Puppet manifests"
  s.email = "tim@sharpe.id.au"
  s.executables = ["rspec-puppet-init"]
  s.files = ["bin/rspec-puppet-init"]
  s.homepage = "https://github.com/rodjek/rspec-puppet/"
  s.licenses = ["MIT"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "RSpec tests for your Puppet manifests"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rspec>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
  end
end
