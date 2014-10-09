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

  it 'should be able to lookup the local ring and build an object 1.8+' do
    File.expects(:exists?).with(builder_file_path).returns(true)
    provider_class.expects(:builder_file_path).twice.returns(builder_file_path)
    # Swift 1.8 output
    provider_class.expects(:swift_ring_builder).returns(
'/etc/swift/account.builder, build version 3
262144 partitions, 3 replicas, 3 zones, 3 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port      replication ip  replication port name weight partitions balance meta
             1     1     1  192.168.101.13  6002         192.168.101.13  6002            1   1.00     262144 0.00
             2     1     2  192.168.101.14  6002         192.168.101.14  6002            1   1.00     262144 200.00  m2
             0     1     3  192.168.101.15  6002         192.168.101.15  6002            1   1.00     262144-100.00  m2
             3     1     1  192.168.101.16  6002         192.168.101.16  6002            1   1.00     262144-100.00
'
    )
    resources = provider_class.lookup_ring
    resources['192.168.101.13:6002/1'].should_not be_nil
    resources['192.168.101.14:6002/1'].should_not be_nil
    resources['192.168.101.15:6002/1'].should_not be_nil
    resources['192.168.101.16:6002/1'].should_not be_nil

    resources['192.168.101.13:6002/1'][:id].should eql '1'
    resources['192.168.101.13:6002/1'][:region].should eql '1'
    resources['192.168.101.13:6002/1'][:zone].should eql '1'
    resources['192.168.101.13:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.13:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.13:6002/1'][:balance].should eql '0.00'
    resources['192.168.101.13:6002/1'][:meta].should eql ''

    resources['192.168.101.14:6002/1'][:id].should eql '2'
    resources['192.168.101.14:6002/1'][:region].should eql '1'
    resources['192.168.101.14:6002/1'][:zone].should eql '2'
    resources['192.168.101.14:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.14:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.14:6002/1'][:balance].should eql '200.00'
    resources['192.168.101.14:6002/1'][:meta].should eql 'm2'
  end

  it 'should be able to lookup the local ring and build an object 1.8.0' do
    File.expects(:exists?).with(builder_file_path).returns(true)
    provider_class.expects(:builder_file_path).twice.returns(builder_file_path)
    # Swift 1.8 output
    provider_class.expects(:swift_ring_builder).returns(
'/etc/swift/account.builder, build version 3
262144 partitions, 3 replicas, 3 zones, 3 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port      name weight partitions balance meta
             1     1     1  192.168.101.13  6002         1   1.00     262144 0.00
             2     1     2  192.168.101.14  6002         1   1.00     262144 200.00  m2
             0     1     3  192.168.101.15  6002         1   1.00     262144-100.00  m2
             3     1     1  192.168.101.16  6002         1   1.00     262144-100.00
'
    )
    resources = provider_class.lookup_ring
    resources['192.168.101.13:6002/1'].should_not be_nil
    resources['192.168.101.14:6002/1'].should_not be_nil
    resources['192.168.101.15:6002/1'].should_not be_nil
    resources['192.168.101.16:6002/1'].should_not be_nil

    resources['192.168.101.13:6002/1'][:id].should eql '1'
    resources['192.168.101.13:6002/1'][:region].should eql '1'
    resources['192.168.101.13:6002/1'][:zone].should eql '1'
    resources['192.168.101.13:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.13:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.13:6002/1'][:balance].should eql '0.00'
    resources['192.168.101.13:6002/1'][:meta].should eql ''

    resources['192.168.101.14:6002/1'][:id].should eql '2'
    resources['192.168.101.14:6002/1'][:region].should eql '1'
    resources['192.168.101.14:6002/1'][:zone].should eql '2'
    resources['192.168.101.14:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.14:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.14:6002/1'][:balance].should eql '200.00'
    resources['192.168.101.14:6002/1'][:meta].should eql 'm2'
  end

  it 'should be able to lookup the local ring and build an object 1.7' do
    File.expects(:exists?).with(builder_file_path).returns(true)
    provider_class.expects(:builder_file_path).twice.returns(builder_file_path)
    # Swift 1.7 output
    provider_class.expects(:swift_ring_builder).returns(
'/etc/swift/account.builder, build version 3
262144 partitions, 3 replicas, 3 zones, 3 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices:    id  region  zone      ip address  port      name weight partitions balance meta
             1     1     1  192.168.101.13  6002         1   1.00     262144    0.00
             2     1     2  192.168.101.14  6002         1   1.00     262144    0.00
             0     1     3  192.168.101.15  6002         1   1.00     262144    0.00
'
    )
    resources = provider_class.lookup_ring
    resources['192.168.101.13:6002/1'].should_not be_nil
    resources['192.168.101.14:6002/1'].should_not be_nil
    resources['192.168.101.15:6002/1'].should_not be_nil

    resources['192.168.101.13:6002/1'][:id].should eql '1'
    resources['192.168.101.13:6002/1'][:region].should eql '1'
    resources['192.168.101.13:6002/1'][:zone].should eql '1'
    resources['192.168.101.13:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.13:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.13:6002/1'][:balance].should eql '0.00'
    resources['192.168.101.13:6002/1'][:meta].should eql ''

    resources['192.168.101.14:6002/1'][:id].should eql '2'
    resources['192.168.101.14:6002/1'][:region].should eql '1'
    resources['192.168.101.14:6002/1'][:zone].should eql '2'
    resources['192.168.101.14:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.14:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.14:6002/1'][:balance].should eql '0.00'
    resources['192.168.101.14:6002/1'][:meta].should eql ''
  end

  it 'should be able to lookup the local ring and build an object legacy' do
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
    resources = provider_class.lookup_ring
    resources['192.168.101.15:6002/1'].should_not be_nil
    resources['192.168.101.13:6002/1'].should_not be_nil
    resources['192.168.101.14:6002/1'].should_not be_nil

    resources['192.168.101.13:6002/1'][:id].should eql '1'
    resources['192.168.101.13:6002/1'][:region].should eql 'none'
    resources['192.168.101.13:6002/1'][:zone].should eql '1'
    resources['192.168.101.13:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.13:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.13:6002/1'][:balance].should eql '0.00'
    resources['192.168.101.13:6002/1'][:meta].should eql ''

    resources['192.168.101.14:6002/1'][:id].should eql '2'
    resources['192.168.101.14:6002/1'][:region].should eql 'none'
    resources['192.168.101.14:6002/1'][:zone].should eql '2'
    resources['192.168.101.14:6002/1'][:weight].should eql '1.00'
    resources['192.168.101.14:6002/1'][:partitions].should eql '262144'
    resources['192.168.101.14:6002/1'][:balance].should eql '0.00'
    resources['192.168.101.14:6002/1'][:meta].should eql ''
  end
end
