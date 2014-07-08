require 'rake'
require 'rspec/core/rake_task'
require 'puppet-lint/tasks/puppet-lint'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/*/*_spec.rb'
  t.rspec_opts = File.read("spec/spec.opts").chomp || ""
end

PuppetLint.configuration.send('disable_80chars')
PuppetLint::configuration.log_format = "%{path}:%{linenumber}:%{check}:%{KIND}:%{message}"

