require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron_router_interface/neutron'

provider_class = Puppet::Type.type(:neutron_router_interface).provider(:neutron)

describe provider_class do

  let :interface_attrs do
    {
      :name            => 'router:subnet',
      :ensure          => 'present',
    }
  end

  let :resource do
    Puppet::Type::Neutron_router_interface.new(interface_attrs)
  end

  let :provider do
    provider_class.new(resource)
  end

  describe 'when creating a router interface' do

    it 'should call port-create with appropriate command line options' do
      provider.class.stubs(:get_tenant_id).returns(interface_attrs[:tenant_id])

      output = 'Added interface b03610fd-ac31-4521-ad06-2ac74af959ad to router router'

      provider.expects(:auth_neutron).with(['router-interface-add',
                                           '--format=shell', 'router', 'subnet=subnet']).returns(output)

      provider.create
    end
  end

  describe 'when accessing attributes of an interface' do
    it 'should return the correct router name' do
      expect(provider.router_name).to eql('router')
    end

    it 'should return the correct subnet name' do
      expect(provider.subnet_name).to eql('subnet')
    end

  end

end
