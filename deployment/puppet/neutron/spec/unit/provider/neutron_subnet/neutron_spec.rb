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
      :tenant_id        => '60f9544eb94c42a6b7e8e98c2be981b1',
      :allocation_pools => 'start=10.0.0.2,end=10.0.0.10',
      :dns_nameservers  => '8.8.8.8',
      :host_routes      => 'destination=12.0.0.0/24,nexthop=10.0.0.1',
    }
  end

  let :resource do
    Puppet::Type::Neutron_subnet.new(subnet_attrs)
  end

  let :provider do
    provider_class.new(resource)
  end

  describe 'when creating a subnet' do

    it 'should call subnet-create with appropriate command line options' do
      provider.class.stubs(:get_tenant_id).returns(subnet_attrs[:tenant_id])

      output = 'Created a new subnet:
allocation_pools="{\"start\": \"10.0.0.2\", \"end\": \"10.0.0.10\"}"
cidr="10.0.0.0/24"
dns_nameservers="8.8.8.8"
enable_dhcp="False"
gateway_ip="10.0.0.1"
host_routes="{\"nexthop\": \"10.0.0.1\", \"destination\": \"12.0.0.0/24\"}"
id="dd5e0ef1-2c88-4b0b-ba08-7df65be87963"
ip_version="4"
name="net1"
network_id="98873773-aa34-4b87-af05-70903659246f"
tenant_id="60f9544eb94c42a6b7e8e98c2be981b1"'

      provider.expects(:auth_neutron).with('subnet-create', '--format=shell',
                                            ["--name=#{subnet_attrs[:name]}",
                                             "--ip-version=#{subnet_attrs[:ip_version]}",
                                             "--gateway-ip=#{subnet_attrs[:gateway_ip]}",
                                             "--disable-dhcp",
                                             "--allocation-pool=#{subnet_attrs[:allocation_pools]}",
                                             "--dns-nameserver=#{subnet_attrs[:dns_nameservers]}",
                                             "--host-route=#{subnet_attrs[:host_routes]}",
                                             "--tenant_id=#{subnet_attrs[:tenant_id]}",
                                             subnet_name],
                                           subnet_attrs[:cidr]).returns(output)

      provider.create
    end
  end

  describe 'when updating a subnet' do
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
