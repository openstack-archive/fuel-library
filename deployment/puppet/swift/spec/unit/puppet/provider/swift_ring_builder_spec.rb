require 'puppet'
require 'mocha/api'
require 'puppet/provider/ring_account_device/swift_ring_builder'
require File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'lib', 'puppet', 'provider', 'swift_ring_builder')

describe 'Puppet::Type.type(:ring_account_device)' do

  before :all do
    type_class = Puppet::Type::Ring_account_device.new(:name => '192.168.1.3:6001')
    @provider_class = Puppet::Type.type(:ring_account_device).provider(:swift_ring_builder).new(type_class)
    # Mocks for swift-ring-builder output and devices
    File.stubs(:exists?).returns(true)
    @provider_class.resource[:mountpoints] = "devicename 1\ndevicename1 1"
    @provider_class.class.stubs(:swift_ring_builder).returns(
'/etc/swift/container.builder, build version 6
262144 partitions, 3.000000 replicas, 1 regions, 3 zones, 6 devices, 0.00 balance
The minimum number of hours before a partition can be reassigned is 1
Devices: id region zone ip address port replication ip replication port name weight partitions balance meta
             1 1 2 192.168.1.3 6002 192.168.1.3 6002 devicename 1.00 131072 0.00 
             1 1 16 192.168.1.3 6002  192.168.1.3 6002 devicename1  1.00     130987   -0.06 
             3 1 3 192.168.1.4 6002 192.168.1.4 6002 devicename1 1.00 131072 0.00 
             5 1 1 192.168.1.2 6002 192.168.1.2 6002 devicename2 1.00 131072 0.00 '
    )
  end

  it 'it should be debug :)' do
    p @provider_class.used_devs
    p @provider_class.class.lookup_ring
  end

  it 'it should be correct parsing for hosts and ports' do
    @provider_class.class.lookup_ring.keys.should == ["192.168.1.3:6002", "192.168.1.4:6002", "192.168.1.2:6002"]
  end

  it 'it should be name of devices if it already exists in ring' do
    @provider_class.used_devs.should == ['devicename','devicename1']
  end

  it 'it should be name of devices' do
    @provider_class.available_devs.should == {"devicename"=>"1", "devicename1"=>"1"}
  end
end
