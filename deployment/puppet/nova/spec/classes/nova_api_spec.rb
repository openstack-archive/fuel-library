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
    describe 'with package version' do
      let :params do
        {:ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-api').with(
        'ensure' => '2012.1-2'
      )}
    end
    describe 'with defaults' do
      it 'should use default params for api-paste.init' do
        verify_contents(subject, '/etc/nova/api-paste.ini',
          [
            '[filter:authtoken]',
            'paste.filter_factory = keystone.middleware.auth_token:filter_factory',
            'auth_host = 127.0.0.1',
            'auth_port = 35357',
            'auth_protocol = http',
            'auth_uri = http://127.0.0.1:35357/v2.0',
            'admin_tenant_name = services',
            'admin_user = nova',
            'admin_password = passw0rd'
          ]
        )
      end
    end
    describe 'with params' do
      let :params do
        {
          :auth_strategy     => 'foo',
          :auth_host         => '10.0.0.1',
          :auth_port         => 1234,
          :auth_protocol     => 'https',
          :admin_tenant_name => 'service2',
          :admin_user        => 'nova2',
          :admin_password    => 'passw0rd2'
        }
      end
      it 'should use default params for api-paste.init' do
        verify_contents(subject, '/etc/nova/api-paste.ini',
          [
            '[filter:authtoken]',
            'paste.filter_factory = keystone.middleware.auth_token:filter_factory',
            'auth_host = 10.0.0.1',
            'auth_port = 1234',
            'auth_protocol = https',
            'auth_uri = https://10.0.0.1:1234/v2.0',
            'admin_tenant_name = service2',
            'admin_user = nova2',
            'admin_password = passw0rd2'
          ]
        )
      end
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
