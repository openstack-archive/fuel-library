require 'spec_helper'

type_class = Puppet::Type.type(:l2_bridge)
provider_class = type_class.provider(:ovs)

describe provider_class do
  let(:resource) do
    type_class.new(
      :ensure       => 'present',
      :use_ovs      => true,
      :external_ids => {
          'bridge-id' => 'br-floating',
      },
      :provider     => :ovs,
      :name         => 'br-floating',
    )
  end

  let(:provider) { resource.provider }

  let(:ovs_vsctl_show) {
  }

  let(:bridge_instances) {
  }

  it 'should exists' do
    expect(provider).not_to be_nil
  end

end
