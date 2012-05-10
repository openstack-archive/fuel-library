require 'spec_helper'

describe 'nova::scheduler' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('nova-scheduler').with(
      'name'    => 'nova-scheduler',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should contain_package('nova-scheduler').with(
      'name'   => 'nova-scheduler',
      'ensure' => 'present',
      'notify' => 'Service[nova-scheduler]'
    ) }
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
    it { should contain_service('nova-scheduler').with(
      'name'    => 'nova-scheduler',
      'ensure'  => 'running',
      'enable'  => true
    )}
    end
    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-scheduler').with(
        'ensure' => '2012.1-2'
      )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-scheduler').with(
      'name'    => 'openstack-nova-scheduler',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should_not contain_package('nova-scheduler') }
  end
end
