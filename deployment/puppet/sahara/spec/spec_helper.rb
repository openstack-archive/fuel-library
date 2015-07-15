require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  config.mock_with :rspec
end

at_exit { RSpec::Puppet::Coverage.report! }
