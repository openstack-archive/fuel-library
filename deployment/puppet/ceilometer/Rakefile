require 'puppetlabs_spec_helper/rake_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'puppet-syntax/tasks/puppet-syntax'

PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_parameter_defaults')
PuppetLint.configuration.send('disable_only_variable_string')

exclude_tests_paths = ['pkg/**/*','vendor/**/*']
PuppetLint.configuration.ignore_paths = exclude_tests_paths
PuppetSyntax.exclude_paths = exclude_tests_paths
