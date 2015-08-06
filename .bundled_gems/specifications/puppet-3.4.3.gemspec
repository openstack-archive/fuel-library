# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "puppet"
  s.version = "3.4.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Puppet Labs"]
  s.date = "2014-02-18"
  s.description = "Puppet, an automated configuration management tool"
  s.email = "info@puppetlabs.com"
  s.executables = ["puppet"]
  s.files = ["bin/puppet"]
  s.homepage = "https://github.com/puppetlabs/puppet"
  s.rdoc_options = ["--title", "Puppet - Configuration Management", "--main", "README.md", "--line-numbers"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "puppet"
  s.rubygems_version = "1.8.23"
  s.summary = "Puppet, an automated configuration management tool"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<facter>, ["~> 1.6"])
      s.add_runtime_dependency(%q<hiera>, ["~> 1.0"])
      s.add_runtime_dependency(%q<rgen>, ["~> 0.6.5"])
    else
      s.add_dependency(%q<facter>, ["~> 1.6"])
      s.add_dependency(%q<hiera>, ["~> 1.0"])
      s.add_dependency(%q<rgen>, ["~> 0.6.5"])
    end
  else
    s.add_dependency(%q<facter>, ["~> 1.6"])
    s.add_dependency(%q<hiera>, ["~> 1.0"])
    s.add_dependency(%q<rgen>, ["~> 0.6.5"])
  end
end
