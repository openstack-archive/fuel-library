require 'rake'
require 'rspec/core/rake_task'
require 'puppetlabs_spec_helper/rake_tasks'

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.pattern = 'spec/*/*__spec.rb'
  t.rspec_opts = File.read("spec/spec.opts").chomp || ""
end
