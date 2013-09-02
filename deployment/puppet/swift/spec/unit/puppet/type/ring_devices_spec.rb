require 'puppet'


describe 'Puppet::Type.type(:ring_devices)' do
  before :all do

    @ring_devices = Puppet::Type.type(:ring_devices).new(:name => 'all',
                                                 :storages => [{
                                                   'name' => 'fuel-swift-01',
                                                   'role' => 'storage',
                                                   'internal_address' => '10.0.0.110',
                                                   'public_address'   => '10.0.204.110',
                                                   'swift_zone'       => 1,
                                                   'mountpoints'=> "dev 1\n dev2 55",
                                                   'storage_address' => '10.0.0.110',
                                                 }])
  end

  #it ':storages param should require a value when Hash and contain "storage_local_net_ip" key' do
  #  expect{
  #    Puppet::Type.type(:ring_devices).new(:name => 'all')
  #  }.to raise_error(Puppet::Error, /should be a Hash/)
  #end
  it 'resources should return Array' do
    @ring_devices.resources.should be_a Array
  end

  it 'should contain correct name for generated type class' do
    @ring_devices.resources.select { |e| e.instance_of? Puppet::Type::Ring_container_device }.should have_at_least(1).items
  end

  it 'should contain correct name for generated type class' do
    @ring_devices.resources.select { |e| e.instance_of? Puppet::Type::Ring_object_device }.should have_at_least(1).items
  end

  it 'should contain correct name for generated type class' do
    @ring_devices.resources.select { |e| e.instance_of? Puppet::Type::Ring_account_device }.should have_at_least(1).items
  end

  it 'should correctly accept external parameters' do
    @ring_devices.resources[0][:name].should == '10.0.0.110:6001'
    @ring_devices.resources[0][:zone].should == 1
    @ring_devices.resources[0][:mountpoints].should == "dev 1\n dev2 55"

  end

  it 'should correctly accept default parameters' do
    ring_devices = Puppet::Type.type(:ring_devices).new(:name => 'all',
                                                        :storages => [ {'storage_address' => '10.0.0.110'}])
    ring_devices.resources[0][:name].should == '10.0.0.110:6001'
    ring_devices.resources[0][:zone].should == 100
    ring_devices.resources[0][:mountpoints].should == "1 1\n2 1"
  end
 end
