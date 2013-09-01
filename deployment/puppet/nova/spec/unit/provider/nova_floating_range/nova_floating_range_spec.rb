require 'puppet'
require 'test/unit'
require 'mocha/setup'
require 'puppet/provider/nova_floating_range/nova_manage'

describe 'Puppet::Type.type(:nova_floating_range)' do

  before :all do
    type_class = Puppet::Type::Nova_floating_range.new(:name => '192.168.1.2-192.168.1.9')
    @provider_class = Puppet::Type.type(:nova_floating_range).provider(:nova_manage).new(type_class)
    # Mock for return existing ip addresses
    floating_ip_info_mock = [OpenStack::Compute::FloatingIPInfo.new('address' => '192.168.1.2'),OpenStack::Compute::FloatingIPInfo.new('address' => '192.168.1.3')]
    @provider_class.stubs(:connect).returns(true)
    @provider_class.connect.stubs(:get_floating_ips_bulk).returns(floating_ip_info_mock)
  end

  it 'ip range should be correct splited' do
    @provider_class.ip_range.should == ['192.168.1.2', '192.168.1.3', '192.168.1.4', '192.168.1.5', '192.168.1.6', '192.168.1.7', '192.168.1.8', '192.168.1.9']
  end

  it 'should correct calculate range and remove existing ips' do
    @provider_class.operate_range.should == ['192.168.1.4', '192.168.1.5', '192.168.1.6', '192.168.1.7', '192.168.1.8', '192.168.1.9']
  end

  it 'should create cidr including first and last ip' do
    @provider_class.mixed_range.should == ['192.168.1.4', '192.168.1.7', '192.168.1.8', '192.168.1.9', '192.168.1.4/30']
  end

  it 'should correct calculate intersection range ips' do
    @provider_class.resource[:ensure] = :absent
    @provider_class.operate_range.should == ['192.168.1.2', '192.168.1.3']
  end
end