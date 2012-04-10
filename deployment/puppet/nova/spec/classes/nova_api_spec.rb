require 'spec_helper'

describe 'nova::api' do

  let :pre_condition do
    'include nova'
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it{ should contain_exec('initial-db-sync').with(
      'command'     => '/usr/bin/nova-manage db sync',
      'refreshonly' => true
    )}
    it { should contain_service('nova-api').with(
      'name'    => 'nova-api',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should contain_package('nova-api').with(
      'name'   => 'nova-api',
      'ensure' => 'present',
      'notify' => 'Service[nova-api]',
      'before' => ['Exec[initial-db-sync]', 'File[/etc/nova/api-paste.ini]']
    ) }
    describe 'with enabled as true' do
      let :params do
        {:enabled => true}
      end
    it { should contain_service('nova-api').with(
      'name'    => 'nova-api',
      'ensure'  => 'running',
      'enable'  => true
    )}
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it{ should contain_exec('initial-db-sync').with(
      'command'     => '/usr/bin/nova-manage db sync',
      'refreshonly' => true
    )}
    it { should contain_service('nova-api').with(
      'name'    => 'openstack-nova-api',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should_not contain_package('nova-api') }
  end
end
