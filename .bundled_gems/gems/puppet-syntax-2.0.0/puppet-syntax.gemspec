# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppet-syntax/version'

Gem::Specification.new do |spec|
  spec.name          = "puppet-syntax"
  spec.version       = PuppetSyntax::VERSION
  spec.authors       = ["Dan Carley"]
  spec.email         = ["dan.carley@gmail.com"]
  spec.description   = %q{Syntax checks for Puppet manifests and templates}
  spec.summary       = %q{Syntax checks for Puppet manifests, templates, and Hiera YAML}
  spec.homepage      = "https://github.com/gds-operations/puppet-syntax"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "rake"

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "gem_publisher", "~> 1.3"
end
