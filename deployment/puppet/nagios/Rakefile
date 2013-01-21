require 'rake'
require 'rspec/core/rake_task'

task :default => [:spec, :lint]

desc "Run all module spec tests"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ['--color']
  t.pattern = 'spec/{classes,defines,unit}/**/*_spec.rb'
end

desc "Build puppet module package"
task :build do
  begin
    Gem::Specification.find_by_name('puppet-module')
  rescue Gem::LoadError, NoMethodError
    require 'puppet/face'
    pmod = Puppet::Face['module', :current]
    pmod.build('./')
  end
end

desc "Check puppet manifests with puppet-lint"
task :lint do
  system("puppet-lint --with-filename --no-80chars-check manifests")
  system("puppet-lint --with-filename --no-80chars-check tests")
end
