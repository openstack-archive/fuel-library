require 'spec_helper'

type_class = Puppet::Type.type(:l2_bridge)
provider_class = type_class.provider(:lnx)

describe provider_class do
  let(:resource) do
    type_class.new(
        :ensure => 'present',
        :use_ovs => true,
        :external_ids => {
            'bridge-id' => 'br-floating',
        },
        :provider => :lnx,
        :name => 'br-floating',
    )
  end

  let(:provider) { resource.provider }

  let(:get_lnx_bridge_list) {{
    'br1' => {
              :ensure  => :present,
              :name    => "br1",
              :members => ["enp2s1"],
              :stp     => true,
              :br_type => 'lnx'
    },
    'br2' => {
              :ensure  => :present,
              :name    => "br2",
              :members => ["enp2s2"],
              :stp     => false,
              :br_type => 'lnx',
    }
  }}

  before(:each) do
    puppet_debug_override()
  end

  it 'should exists' do
    expect(provider).not_to be_nil
  end

  it 'should generate the array on provider instances' do
    provider_class.stubs(:get_ovs_bridge_list).returns {}
    provider_class.stubs(:get_lnx_bridge_list).returns get_lnx_bridge_list
    instances = provider_class.instances
    expect(instances).to be_a Array
    expect(instances.length).to eq 2
    instances.each do |provider|
      expect(provider).to be_a Puppet::Type::L2_bridge::ProviderLnx
      class << provider
          def property_hash
              @property_hash
          end
      end
    end
    expect(instances.map { |p| p.property_hash }).to eq([{
      :ensure   => :present,
      :name     => "br1",
      :members  => ['enp2s1'],
      :stp      => true,
      :br_type  => "lnx",
    },{
      :ensure   => :present,
      :members  => ['enp2s2'],
      :name     => "br2",
      :br_type  => "lnx",
      :stp      => false,
    }])
  end

end
