require 'puppetlabs_spec_helper/module_spec_helper'
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr'
  c.hook_into :faraday
end
