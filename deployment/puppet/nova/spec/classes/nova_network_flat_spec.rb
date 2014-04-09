require 'spec_helper'

describe 'nova::network::flat' do

  describe 'with only required parameters' do
    let :params do
      {
        :fixed_range    => '10.0.0.0/32'
      }
    end

    it { should contain_nova_config('DEFAULT/network_manager').with_value('nova.network.manager.FlatManager') }
    it { should_not contain_nova_config('DEFAULT/public_interface') }
    it { should contain_nova_config('DEFAULT/fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('DEFAULT/flat_network_bridge').with_value('br100') }
    it { should contain_nova_config('DEFAULT/flat_interface').with_value(nil) }
  end

  describe 'when overriding class parameters' do

    let :params do
      {
        :flat_interface => 'eth1',
        :fixed_range    => '10.0.0.0/32',
        :public_interface    => 'eth0',
        :flat_network_bridge => 'br1001',
      }
    end

    it { should contain_nova_config('DEFAULT/public_interface').with_value('eth0') }
    it { should contain_nova_config('DEFAULT/flat_network_bridge').with_value('br1001') }
    it { should contain_nova_config('DEFAULT/fixed_range').with_value('10.0.0.0/32') }
    it { should contain_nova_config('DEFAULT/flat_interface').with_value('eth1') }

  end

end
