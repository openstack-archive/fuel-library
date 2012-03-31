require 'spec_helper'

describe 'nova::objectstore' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('nova-objectstore').with(
      'name'    => 'nova-objectstore',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should contain_package('nova-objectstore').with(
      'name'   => 'nova-objectstore',
      'ensure' => 'present',
      'notify' => 'Service[nova-objectstore]'
    ) }
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
    it { should contain_service('nova-objectstore').with(
      'name'    => 'nova-objectstore',
      'ensure'  => 'running',
      'enable'  => true
    )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-objectstore').with(
      'name'    => 'openstack-nova-objectstore',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should_not contain_package('nova-objectstore') }
  end
end
