# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "rgen"
  s.version = "0.6.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Martin Thiede"]
  s.date = "2013-08-30"
  s.description = "RGen is a framework for Model Driven Software Development (MDSD) in Ruby. This means that it helps you build Metamodels, instantiate Models, modify and transform Models and finally generate arbitrary textual content from it."
  s.email = "martin dot thiede at gmx de"
  s.extra_rdoc_files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.files = ["README.rdoc", "CHANGELOG", "MIT-LICENSE"]
  s.homepage = "http://ruby-gen.org"
  s.rdoc_options = ["--main", "README.rdoc", "-x", "test", "-x", "metamodels", "-x", "ea_support/uml13*"]
  s.require_paths = ["lib"]
  s.rubyforge_project = "rgen"
  s.rubygems_version = "1.8.23"
  s.summary = "Ruby Modelling and Generator Framework"

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
