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
      'name'       => 'nova-cert',
      'ensure'     => 'stopped',
      'hasstatus'  => true,
      'enable'     => false
    )}
    it { should contain_package('nova-cert').with(
      'name'   => 'nova-cert',
      'ensure' => 'present',
      'notify' => 'Service[nova-cert]'
    )}
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
      it { should contain_service('nova-cert').with(
        'name'      => 'nova-cert',
        'ensure'    => 'running',
        'hasstatus' => true,
        'enable'    => true
      )}
    end
    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-cert').with(
        'ensure' => '2012.1-2'
      )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-cert').with(
      'name'      => 'openstack-nova-cert',
      'ensure'    => 'stopped',
      'hasstatus' => true,
      'enable'    => false
    )}
    it { should contain_package('nova-cert').with_name('openstack-nova-cert') }
  end
end
