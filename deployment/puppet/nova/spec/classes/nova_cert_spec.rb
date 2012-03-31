require 'spec_helper'

describe 'nova::cert' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('nova-cert').with(
      'name'    => 'openstack-nova-cert',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
    it { should contain_service('nova-cert').with(
      'name'    => 'openstack-nova-cert',
      'ensure'  => 'running',
      'enable'  => true
    )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-cert').with(
      'name'    => 'openstack-nova-cert',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should_not contain_package('nova-network') }
  end
end
