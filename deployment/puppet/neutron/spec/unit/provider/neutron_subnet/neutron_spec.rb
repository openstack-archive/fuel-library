require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron_subnet/neutron'

provider_class = Puppet::Type.type(:neutron_subnet).provider(:neutron)

describe provider_class do

  let :subnet_name do
    'net1'
  end

  let :subnet_attrs do
    {
      :name             => subnet_name,
      :ensure           => 'present',
      :cidr             => '10.0.0.0/24',
      :ip_version       => '4',
      :gateway_ip       => '10.0.0.1',
      :enable_dhcp      => 'False',
      :network_name     => 'net1',
      :tenant_id        => '',
      :allocation_pools => 'start=7.0.0.1,end=7.0.0.10',
      :dns_nameservers  => '8.8.8.8',
      :host_routes      => 'destination=12.0.0.0/24,nexthop=10.0.0.1',
    }
  end

  describe 'when updating a subnet' do
    let :resource do
      Puppet::Type::Neutron_subnet.new(subnet_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    it 'should call subnet-update to change gateway_ip' do
      provider.expects(:auth_neutron).with('subnet-update',
                                           '--gateway-ip=10.0.0.2',
                                           subnet_name)
      provider.gateway_ip=('10.0.0.2')
    end

    it 'should call subnet-update to remove gateway_ip with empty string' do
      provider.expects(:auth_neutron).with('subnet-update',
                                           '--no-gateway',
                                           subnet_name)
      provider.gateway_ip=('')
    end

    it 'should call subnet-update to change enable_dhcp' do
      provider.expects(:auth_neutron).with('subnet-update',
                                           '--enable-dhcp',
                                           subnet_name)
      provider.enable_dhcp=('True')
    end

    it 'should call subnet-update to change dns_nameservers' do
      provider.expects(:auth_neutron).with('subnet-update',
                                           [subnet_name,
                                           '--dns-nameservers',
                                           'list=true',
                                           '9.9.9.9'])
      provider.dns_nameservers=(['9.9.9.9'])
    end

    it 'should call subnet-update to change host_routes' do
      provider.expects(:auth_neutron).with('subnet-update',
                                           [subnet_name,
                                            '--host-routes',
                                            'type=dict',
                                            'list=true',
                                            'destination=12.0.0.0/24,nexthop=10.0.0.2'])
      provider.host_routes=(['destination=12.0.0.0/24,nexthop=10.0.0.2'])
    end

    it 'should not update if dns_nameservers are empty' do
      provider.dns_nameservers=('')
    end

    it 'should not update if host_routes are empty' do
      provider.host_routes=('')
    end
  end

  describe 'when updating a subnet (reverse)' do
    let :subnet_attrs_mod do
      subnet_attrs.merge!({:enable_dhcp => 'True'})
    end
    let :resource do
      Puppet::Type::Neutron_subnet.new(subnet_attrs_mod)
    end

    let :provider do
      provider_class.new(resource)
    end


    it 'should call subnet-update to change enable_dhcp' do
      provider.expects(:auth_neutron).with('subnet-update',
                                           '--disable-dhcp',
                                           subnet_name)
      provider.enable_dhcp=('False')
    end
  end
end
