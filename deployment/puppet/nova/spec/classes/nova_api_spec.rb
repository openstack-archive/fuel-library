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
      'name'      => 'nova-api',
      'ensure'    => 'stopped',
      'hasstatus' => true,
      'enable'    => false
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
      'name'      => 'nova-api',
      'ensure'    => 'running',
      'hasstatus' => true,
      'enable'    => true
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
      it 'should use default params for nova.conf' do
        should contain_nova_config(
         'keystone_authtoken/auth_host').with_value('127.0.0.1')
        should contain_nova_config(
          'keystone_authtoken/auth_port').with_value('35357')
        should contain_nova_config(
          'keystone_authtoken/auth_protocol').with_value('http')
        should contain_nova_config(
          'keystone_authtoken/auth_uri').with_value('http://127.0.0.1:5000/')
        should contain_nova_config(
          'keystone_authtoken/auth_admin_prefix').with_ensure('absent')
        should contain_nova_config(
          'keystone_authtoken/admin_tenant_name').with_value('services')
        should contain_nova_config(
          'keystone_authtoken/admin_user').with_value('nova')
        should contain_nova_config(
          'keystone_authtoken/admin_password').with_value('passw0rd').with_secret(true)
      end
      it { should contain_nova_config('DEFAULT/ec2_listen').with('value' => '0.0.0.0') }
      it { should contain_nova_config('DEFAULT/osapi_compute_listen').with('value' => '0.0.0.0') }
      it { should contain_nova_config('DEFAULT/metadata_listen').with('value' => '0.0.0.0') }
      it { should contain_nova_config('DEFAULT/osapi_volume_listen').with('value' => '0.0.0.0') }
      it 'should unconfigure neutron_metadata proxy' do
        should contain_nova_config('DEFAULT/service_neutron_metadata_proxy').with('value' => false)
        should contain_nova_config('DEFAULT/neutron_metadata_proxy_shared_secret').with('ensure' => 'absent')
      end
    end
    describe 'with params' do
      let :facts do
        {
          :osfamily          => 'RedHat',
          :processorcount    => 5
        }
      end
      let :params do
        {
          :auth_host                            => '10.0.0.1',
          :auth_port                            => 1234,
          :auth_protocol                        => 'https',
          :auth_admin_prefix                    => '/keystone/admin',
          :auth_uri                             => 'https://10.0.0.1:9999/',
          :admin_tenant_name                    => 'service2',
          :admin_user                           => 'nova2',
          :admin_password                       => 'passw0rd2',
          :api_bind_address                     => '192.168.56.210',
          :metadata_listen                      => '127.0.0.1',
          :volume_api_class                     => 'nova.volume.cinder.API',
          :use_forwarded_for                    => false,
          :neutron_metadata_proxy_shared_secret => 'secrete',
          :ratelimits                            => '(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)'
        }
      end
      it 'should use defined params for nova.conf and api-paste.ini' do
        should contain_nova_config(
          'keystone_authtoken/auth_host').with_value('10.0.0.1')
        should contain_nova_config(
          'keystone_authtoken/auth_port').with_value('1234')
        should contain_nova_config(
          'keystone_authtoken/auth_protocol').with_value('https')
        should contain_nova_config(
          'keystone_authtoken/auth_admin_prefix').with_value('/keystone/admin')
        should contain_nova_config(
          'keystone_authtoken/auth_uri').with_value('https://10.0.0.1:9999/')
        should contain_nova_config(
          'keystone_authtoken/admin_tenant_name').with_value('service2')
        should contain_nova_config(
          'keystone_authtoken/admin_user').with_value('nova2')
        should contain_nova_config(
          'keystone_authtoken/admin_password').with_value('passw0rd2').with_secret(true)
        should contain_nova_paste_api_ini(
          'filter:ratelimit/limits').with_value('(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)')
      end
      it { should contain_nova_config('DEFAULT/ec2_listen').with('value' => '192.168.56.210') }
      it { should contain_nova_config('DEFAULT/osapi_compute_listen').with('value' => '192.168.56.210') }
      it { should contain_nova_config('DEFAULT/metadata_listen').with('value' => '127.0.0.1') }
      it { should contain_nova_config('DEFAULT/osapi_volume_listen').with('value' => '192.168.56.210') }
      it { should contain_nova_config('DEFAULT/use_forwarded_for').with('value' => false) }
      it { should contain_nova_config('DEFAULT/osapi_compute_workers').with('value' => '5') }
      it { should contain_nova_config('DEFAULT/service_neutron_metadata_proxy').with('value' => true) }
      it { should contain_nova_config('DEFAULT/neutron_metadata_proxy_shared_secret').with('value' => 'secrete') }
    end

    [
      '/keystone/',
      'keystone/',
      'keystone',
      '/keystone/admin/',
      'keystone/admin/',
      'keystone/admin'
    ].each do |auth_admin_prefix|
      describe "with auth_admin_prefix_containing incorrect value #{auth_admin_prefix}" do
        let :params do
          {
            :auth_admin_prefix => auth_admin_prefix,
            :admin_password    => 'dummy'
          }
        end

        it { expect { should contain_nova_config('keystone_authtoken/auth_admin_prefix') }.to \
          raise_error(Puppet::Error, /validate_re\(\): "#{auth_admin_prefix}" does not match/) }
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
    it { should contain_package('nova-api').with_name('openstack-nova-api') }
  end
end
