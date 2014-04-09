require 'spec_helper'

describe 'nova::api' do

  let :pre_condition do
    'include nova'
  end

  let :params do
    { :admin_password => 'passw0rd' }
  end

  let :facts do
    { :processorcount => 5 }
  end

  shared_examples 'nova-api' do

    context 'with default parameters' do

      it 'installs nova-api package and service' do
        should contain_service('nova-api').with(
          :name      => platform_params[:nova_api_service],
          :ensure    => 'stopped',
          :hasstatus => true,
          :enable    => false
        )
        should contain_package('nova-api').with(
          :name   => platform_params[:nova_api_package],
          :ensure => 'present',
          :notify => 'Service[nova-api]'
        )
      end

      it 'configures keystone_authtoken middleware' do
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
          'keystone_authtoken/auth_version').with_ensure('absent')
        should contain_nova_config(
          'keystone_authtoken/admin_tenant_name').with_value('services')
        should contain_nova_config(
          'keystone_authtoken/admin_user').with_value('nova')
        should contain_nova_config(
          'keystone_authtoken/admin_password').with_value('passw0rd').with_secret(true)
      end

      it 'configures various stuff' do
        should contain_nova_config('DEFAULT/ec2_listen').with('value' => '0.0.0.0')
        should contain_nova_config('DEFAULT/osapi_compute_listen').with('value' => '0.0.0.0')
        should contain_nova_config('DEFAULT/metadata_listen').with('value' => '0.0.0.0')
        should contain_nova_config('DEFAULT/osapi_volume_listen').with('value' => '0.0.0.0')
        should contain_nova_config('DEFAULT/osapi_compute_workers').with('value' => '5')
        should contain_nova_config('DEFAULT/metadata_workers').with('value' => '5')
        should contain_nova_config('conductor/workers').with('value' => '5')
      end

      it 'unconfigures neutron_metadata proxy' do
        should contain_nova_config('DEFAULT/service_neutron_metadata_proxy').with(:value => false)
        should contain_nova_config('DEFAULT/neutron_metadata_proxy_shared_secret').with(:ensure => 'absent')
      end
    end

    context 'with deprecated parameters' do
      before do
        params.merge!({
          :workers           => 1,
        })
      end
      it 'configures various stuff' do
        should contain_nova_config('DEFAULT/osapi_compute_workers').with('value' => '1')
      end
    end

    context 'with overridden parameters' do
      before do
        params.merge!({
          :enabled                              => true,
          :ensure_package                       => '2012.1-2',
          :auth_host                            => '10.0.0.1',
          :auth_port                            => 1234,
          :auth_protocol                        => 'https',
          :auth_admin_prefix                    => '/keystone/admin',
          :auth_uri                             => 'https://10.0.0.1:9999/',
          :auth_version                         => 'v3.0',
          :admin_tenant_name                    => 'service2',
          :admin_user                           => 'nova2',
          :admin_password                       => 'passw0rd2',
          :api_bind_address                     => '192.168.56.210',
          :metadata_listen                      => '127.0.0.1',
          :volume_api_class                     => 'nova.volume.cinder.API',
          :use_forwarded_for                    => false,
          :ratelimits                           => '(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)',
          :neutron_metadata_proxy_shared_secret => 'secrete',
          :osapi_compute_workers                => 1,
          :metadata_workers                     => 2,
          :conductor_workers                    => 3,
        })
      end

      it 'installs nova-api package and service' do
        should contain_package('nova-api').with(
          :name   => platform_params[:nova_api_package],
          :ensure => '2012.1-2'
        )
        should contain_service('nova-api').with(
          :name      => platform_params[:nova_api_service],
          :ensure    => 'running',
          :hasstatus => true,
          :enable    => true
        )
      end

      it 'configures keystone_authtoken middleware' do
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
          'keystone_authtoken/auth_version').with_value('v3.0')
        should contain_nova_config(
          'keystone_authtoken/admin_tenant_name').with_value('service2')
        should contain_nova_config(
          'keystone_authtoken/admin_user').with_value('nova2')
        should contain_nova_config(
          'keystone_authtoken/admin_password').with_value('passw0rd2').with_secret(true)
        should contain_nova_paste_api_ini(
          'filter:ratelimit/limits').with_value('(GET, "*", .*, 100, MINUTE);(POST, "*", .*, 200, MINUTE)')
      end

      it 'configures various stuff' do
        should contain_nova_config('DEFAULT/ec2_listen').with('value' => '192.168.56.210')
        should contain_nova_config('DEFAULT/osapi_compute_listen').with('value' => '192.168.56.210')
        should contain_nova_config('DEFAULT/metadata_listen').with('value' => '127.0.0.1')
        should contain_nova_config('DEFAULT/osapi_volume_listen').with('value' => '192.168.56.210')
        should contain_nova_config('DEFAULT/use_forwarded_for').with('value' => false)
        should contain_nova_config('DEFAULT/osapi_compute_workers').with('value' => '1')
        should contain_nova_config('DEFAULT/metadata_workers').with('value' => '2')
        should contain_nova_config('conductor/workers').with('value' => '3')
        should contain_nova_config('DEFAULT/service_neutron_metadata_proxy').with('value' => true)
        should contain_nova_config('DEFAULT/neutron_metadata_proxy_shared_secret').with('value' => 'secrete')
      end
    end

    [
      '/keystone/',
      'keystone/',
      'keystone',
      '/keystone/admin/',
      'keystone/admin/',
      'keystone/admin'
    ].each do |auth_admin_prefix|
      context "with auth_admin_prefix_containing incorrect value #{auth_admin_prefix}" do
        before do
          params.merge!({ :auth_admin_prefix => auth_admin_prefix })
        end
        it { expect { should contain_nova_config('keystone_authtoken/auth_admin_prefix') }.to \
          raise_error(Puppet::Error, /validate_re\(\): "#{auth_admin_prefix}" does not match/) }
      end
    end

    context 'while not managing service state' do
      before do
        params.merge!({
          :enabled           => false,
          :manage_service    => false,
        })
      end

      it { should contain_service('nova-api').without_ensure }
    end
  end

  context 'on Debian platforms' do
    before do
      facts.merge!( :osfamily => 'Debian' )
    end

    let :platform_params do
      { :nova_api_package => 'nova-api',
        :nova_api_service => 'nova-api' }
    end

    it_behaves_like 'nova-api'
  end

  context 'on RedHat platforms' do
    before do
      facts.merge!( :osfamily => 'RedHat' )
    end

    let :platform_params do
      { :nova_api_package => 'openstack-nova-api',
        :nova_api_service => 'openstack-nova-api' }
    end

    it_behaves_like 'nova-api'
  end

end
