require 'spec_helper'

describe 'nova::network' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('nova-network').with(
      'name'    => 'nova-network',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should contain_package('nova-network').with(
      'name'   => 'nova-network',
      'ensure' => 'present',
      'notify' => 'Service[nova-network]'
    ) }
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
    it { should contain_service('nova-network').with(
      'name'    => 'nova-network',
      'ensure'  => 'running',
      'enable'  => true
    )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-network').with(
      'name'    => 'openstack-nova-network',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should_not contain_package('nova-network') }
  end
end
