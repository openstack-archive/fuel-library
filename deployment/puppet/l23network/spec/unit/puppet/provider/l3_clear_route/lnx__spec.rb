require 'spec_helper'

provider_class = Puppet::Type.type(:l3_clear_route).provider(:lnx)

describe provider_class do
  let(:name) { 'default' }

  let(:resource) do
    Puppet::Type.type(:l3_clear_route).new(
      :name        => name,
      :ensure      => 'absent',
      :destination => 'default',
      :gateway     => '10.109.2.1',
      :interface   => 'br-fw-admin',
      :provider    => 'lnx',
    )
  end

  let(:provider) do
    provider = provider_class.new
    provider.resource = resource
    provider
  end


  get_routes_res = [{:interface=>"p2p22", :destination=>"default", :metric=>0, :gateway=>"172.18.128.1"},
                    {:interface=>"fuelbr286", :destination=>"10.109.0.0/24", :metric=>0, :gateway=>nil},
                    {:interface=>"fuelbr287", :destination=>"10.109.1.0/24", :metric=>0, :gateway=>nil},
                    {:interface=>"fuelbr282", :destination=>"10.109.2.0/24", :metric=>0, :gateway=>nil},
                    {:interface=>"fuelbr283", :destination=>"10.109.3.0/24", :metric=>0, :gateway=>nil},
                    {:interface=>"p2p222", :destination=>"172.18.128.0/25", :metric=>0, :gateway=>nil},
                    {:interface=>"virbr0", :destination=>"192.168.122.0/24", :metric=>0, :gateway=>nil}]

    before(:each) do
      puppet_debug_override()
      provider.class.stubs(:get_routes).with().returns(get_routes_res)
    end

    it 'Delete existing default route' do
      provider.class.stubs(:ip).with(['--force', 'route', 'delete', name, 'via', '172.18.128.1', 'dev', 'p2p22']).returns(0)
      provider.destroy
    end

    it 'Route is deleted by hotplug system during destroy executing' do
      provider.class.stubs(:ip).with(['--force', 'route', 'delete', name, 'via', '172.18.128.1', 'dev', 'p2p22']).raises('RTNETLINK answers: No such process')
      provider.destroy
    end

  end
# vim: set ts=2 sw=2 et
