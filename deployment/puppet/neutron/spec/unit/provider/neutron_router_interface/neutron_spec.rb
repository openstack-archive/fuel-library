require 'puppet'
require 'spec_helper'
require 'puppet/provider/neutron_router_interface/neutron'

provider_class = Puppet::Type.type(:neutron_router_interface).
  provider(:neutron)

describe provider_class do

  let :interface_attrs do
    {
      :name            => 'router:subnet',
      :ensure          => 'present',
    }
  end

  describe 'when accessing attributes of an interface' do
    let :resource do
      Puppet::Type::Neutron_router_interface.new(interface_attrs)
    end

    let :provider do
      provider_class.new(resource)
    end

    it 'should return the correct router name' do
      expect(provider.router_name).to eql('router')
    end

    it 'should return the correct subnet name' do
      expect(provider.subnet_name).to eql('subnet')
    end

  end

end
