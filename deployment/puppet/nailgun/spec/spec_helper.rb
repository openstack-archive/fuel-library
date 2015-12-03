require 'rspec-puppet'
require 'fakefs/spec_helpers'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
  c.include FakeFS::SpecHelpers, fakefs: true
end
