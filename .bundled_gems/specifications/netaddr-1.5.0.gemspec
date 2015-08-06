# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = "netaddr"
  s.version = "1.5.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Dustin Spinhirne"]
  s.date = "2008-11-07"
  s.extra_rdoc_files = ["README", "Errors", "changelog"]
  s.files = ["README", "Errors", "changelog"]
  s.require_paths = ["lib"]
  s.rubygems_version = "1.8.23"
  s.summary = "A package for manipulating network addresses."

  if s.respond_to? :specification_version then
    s.specification_version = 2

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
