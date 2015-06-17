require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_parameter_defaults')
PuppetLint.configuration.send('disable_class_inherits_from_params_class')

exclude_tests_paths = ['pkg/**/*','vendor/**/*']
PuppetLint.configuration.ignore_paths = exclude_tests_paths
PuppetSyntax.exclude_paths = exclude_tests_paths

desc "Lint metadata.json file"
task :metadata do
  sh "metadata-json-lint metadata.json"
end
