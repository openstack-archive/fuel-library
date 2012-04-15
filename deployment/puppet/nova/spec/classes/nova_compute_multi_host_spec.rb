require 'spec_helper'

describe 'nova::compute::multi_host' do

  let :pre_condition do
    'class { "nova": network_manager => "nova.network.manager.VlanManager" }'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should include_class('nova::api') }
    it { should contain_nova_config('enabled_apis').with_value('metadata') }
  end
end
