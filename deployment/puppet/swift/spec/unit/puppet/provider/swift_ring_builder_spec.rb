require 'puppet'
require 'mocha'
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
'/etc/swift/account.builder, build version 3
262144 partitions, 3 replicas, 3 zones, 3 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  zone      ip address  port      name weight partitions balance meta
             2     2  192.168.101.14  6002         1   1.00     262144    0.00 
             0     3  192.168.101.15  6002         1   1.00     262144    0.00 
             1     1  192.168.101.13  6002         1   1.00     262144    0.00 

'
    )
    resources = provider_class.lookup_ring.inspect
    resources['192.168.101.15:6002/1'].should_not be_nil
    resources['192.168.101.13:6002/1'].should_not be_nil
    resources['192.168.101.14:6002/1'].should_not be_nil
  end
end
