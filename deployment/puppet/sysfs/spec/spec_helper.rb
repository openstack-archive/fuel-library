require 'puppetlabs_spec_helper/module_spec_helper'

RSpec.configure do |config|
  config.mock_with :rspec do |mock|
    mock.syntax = :expect
  end
end
