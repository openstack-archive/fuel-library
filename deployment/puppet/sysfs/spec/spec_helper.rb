require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'

RSpec.configure do |c|
  c.mock_with :rspec do |mock|
    mock.syntax = :expect
  end
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
end

# TODO(aschultz): WARNING: Using the `raise_error` matcher without providing a specific error or message risks false positives, since `raise_error` will match when Ruby raises a `NoMethodError`, `NameError` or `ArgumentError`, potentially allowing the expectation to pass without even executing the method you are intending to call.
RSpec::Expectations.configuration.warn_about_potential_false_positives = false

at_exit { RSpec::Puppet::Coverage.report! }
