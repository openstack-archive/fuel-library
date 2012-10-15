require 'spec_helper'

describe 'nova::api' do

  let :pre_condition do
    'include nova'
  end

  let :params do
    {:admin_password => 'passw0rd'}
  end

  describe 'on debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end
    it { should contain_service('nova-api').with(
      'name'    => 'nova-api',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should contain_package('nova-api').with(
      'name'   => 'nova-api',
      'ensure' => 'present',
      'notify' => 'Service[nova-api]'
    ) }
    describe 'with enabled as true' do
      let :params do
        {:admin_password => 'passw0rd', :enabled => true}
      end
    it { should contain_service('nova-api').with(
      'name'    => 'nova-api',
      'ensure'  => 'running',
      'enable'  => true
    )}
    end
    describe 'with package version' do
      let :params do
        {:admin_password => 'passw0rd', :ensure_package => '2012.1-2'}
      end
      it { should contain_package('nova-api').with(
        'ensure' => '2012.1-2'
      )}
    end
    describe 'with defaults' do
      it 'should use default params for api-paste.init' do
        should contain_nova_paste_api_ini(
         'filter:authtoken/auth_host').with_value('127.0.0.1')
        should contain_nova_paste_api_ini(
          'filter:authtoken/auth_port').with_value('35357')
        should contain_nova_paste_api_ini(
          'filter:authtoken/auth_protocol').with_value('http')
        should contain_nova_paste_api_ini(
          'filter:authtoken/admin_tenant_name').with_value('services')
        should contain_nova_paste_api_ini(
          'filter:authtoken/admin_user').with_value('nova')
        should contain_nova_paste_api_ini(
          'filter:authtoken/admin_password').with_value('passw0rd')
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
        should contain_nova_paste_api_ini(
         'filter:authtoken/auth_host').with_value('10.0.0.1')
        should contain_nova_paste_api_ini(
          'filter:authtoken/auth_port').with_value('1234')
        should contain_nova_paste_api_ini(
          'filter:authtoken/auth_protocol').with_value('https')
        should contain_nova_paste_api_ini(
          'filter:authtoken/admin_tenant_name').with_value('service2')
        should contain_nova_paste_api_ini(
          'filter:authtoken/admin_user').with_value('nova2')
        should contain_nova_paste_api_ini(
          'filter:authtoken/admin_password').with_value('passw0rd2')
      end
    end
  end
  describe 'on rhel' do
    let :facts do
      { :osfamily => 'RedHat' }
    end
    it { should contain_service('nova-api').with(
      'name'    => 'openstack-nova-api',
      'ensure'  => 'stopped',
      'enable'  => false
    )}
    it { should_not contain_package('nova-api') }
  end
end
