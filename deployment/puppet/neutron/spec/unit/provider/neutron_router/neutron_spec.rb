require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron_router/neutron'

provider_class = Puppet::Type.type(:neutron_router).provider(:neutron)

describe provider_class do

  let :router_name do
    'router1'
  end

  let :router_attrs do
    {
      :name            => router_name,
      :ensure          => 'present',
      :admin_state_up  => 'True',
      :tenant_id       => '',
    }
  end

  describe 'when updating a router' do
    let :resource do
      Puppet::Type::Neutron_router.new(router_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

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

end
