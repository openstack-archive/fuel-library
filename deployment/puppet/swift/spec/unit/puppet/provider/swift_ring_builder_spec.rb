require 'puppet'
require 'mocha/api'
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'puppet', 'provider', 'swift_ring_builder')
RSpec.configure do |config|
  config.mock_with :mocha
end
provider_class = Puppet::Provider::SwiftRingBuilder
describe provider_class do

  let :builder_file_path do
    '/etc/swift/account.builder'
  end

  it 'should be able to lookup the local ring and build an object' do
    File.expects(:exists?).with(builder_file_path).returns(true)
    provider_class.expects(:builder_file_path).twice.returns(builder_file_path)
    provider_class.expects(:swift_ring_builder).returns(
'/etc/swift/account.builder, build version 7
262144 partitions, 3.000000 replicas, 1 regions, 1 zones, 6 devices, 50.31 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port      name weight partitions balance meta
             1     1   100      10.108.7.8  6002         1   2.00     130798 -25.16
             2     1   100      10.108.7.6  6002         2   1.00     130935  49.84 
             5     1   100      10.108.7.7  6002         1   2.00     174762  -0.00 '
    )
    resources = provider_class.lookup_ring.inspect
    resources['10.108.7.8:6002'].should_not be_nil
    resources['10.108.7.6:6002'].should_not be_nil
    resources['10.108.7.7:6002'].should_not be_nil
  end
end
