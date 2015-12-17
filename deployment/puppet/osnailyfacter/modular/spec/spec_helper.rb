require 'rspec'

RSpec.configure do |config|
  config.mock_with :rspec do |c|
    c.syntax = :expect
  end
end
