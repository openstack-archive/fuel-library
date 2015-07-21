require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron_router/neutron'

provider_class = Puppet::Type.type(:neutron_router).provider(:neutron)
klass = Puppet::Provider::Neutron

describe provider_class do

  let :router_name do
    'router1'
  end

  let :router_attrs do
    {
      :name            => router_name,
      :ensure          => 'present',
      :admin_state_up  => 'True',
      :tenant_id       => '60f9544eb94c42a6b7e8e98c2be981b1',
    }
  end

  let :resource do
    Puppet::Type::Neutron_router.new(router_attrs)
  end

  let :provider do
    provider_class.new(resource)
  end

  describe 'when creating a router' do

    it 'should call router-create with appropriate command line options' do
      provider.class.stubs(:get_tenant_id).returns(router_attrs[:tenant_id])

      output = 'Created a new router:
admin_state_up="True"
external_gateway_info=""
id="c5f799fa-b3e0-47ca-bdb7-abeff209b816"
name="router1"
status="ACTIVE"
tenant_id="60f9544eb94c42a6b7e8e98c2be981b1"'

      provider.expects(:auth_neutron).with('router-create',
                                           '--format=shell', ["--tenant_id=#{router_attrs[:tenant_id]}"],
                                           router_name).returns(output)

      provider.create
    end
  end

  describe 'when updating a router' do

    it 'should call router-update to change admin_state_up' do
      provider.expects(:auth_neutron).with('router-update',
                                           '--admin-state-up=False',
                                           router_name)
      provider.admin_state_up=('False')
    end

    it 'should call router-gateway-clear for an empty network name' do
      provider.expects(:auth_neutron).with('router-gateway-clear',
                                           router_name)
      provider.gateway_network_name=('')
    end

    it 'should call router-gateway-set to configure an external network' do
      provider.expects(:auth_neutron).with('router-gateway-set',
                                           router_name,
                                           'net1')
      provider.gateway_network_name=('net1')
    end

  end

  describe 'when parsing an external gateway info' do
    let :resource do
      Puppet::Type::Neutron_router.new(router_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    after :each do
      klass.reset
    end

    it 'should detect a gateway net id' do
      klass.stubs(:auth_neutron).returns(
        'external_gateway_info="{\"network_id\": \"1b-b1\", \"enable_snat\": true, \"external_fixed_ips\": [{\"subnet_id\": \"1b-b1\", \"ip_address\": \"1.1.1.1\"}]}"'
      )
      result = klass.get_neutron_resource_attrs 'foo', nil
      expect(provider.parse_gateway_network_id(result['external_gateway_info'])).to eql('1b-b1')
    end

    it 'should return empty value, if there is no net id found' do
      klass.stubs(:auth_neutron).returns('external_gateway_info="{}"')
      result = klass.get_neutron_resource_attrs 'foo', nil
      expect(provider.parse_gateway_network_id(result['external_gateway_info'])).to eql('')
    end

  end

end
