require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-config.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') == true and Noop.hiera('role') =~ /controller/)

      let(:facts) {
        Noop.ubuntu_facts.merge({
          :processorcount => '6'
        })
      }

      let(:processorcount) do
        6
      end

      context 'with Neutron-server' do
        neutron_config = Noop.hiera_hash('neutron_config')
        management_vip = Noop.hiera('management_vip')
        service_endpoint = Noop.hiera('service_endpoint', management_vip)

        it 'database options' do
          database_vip        = Noop.hiera('database_vip')
          neutron_db_password = neutron_config.fetch('database', {}).fetch('passwd')
          neutron_db_user     = neutron_config.fetch('database', {}).fetch('user', 'neutron')
          neutron_db_name     = neutron_config.fetch('database', {}).fetch('name', 'neutron')
          neutron_db_host     = neutron_config.fetch('database', {}).fetch('host', database_vip)
          neutron_db_uri = "mysql://#{neutron_db_user}:#{neutron_db_password}@#{neutron_db_host}/#{neutron_db_name}?&read_timeout=60"
          should contain_class('neutron::server').with(
            'sync_db'                 => 'false',
            'database_retry_interval' => '2',
            'database_connection'     => neutron_db_uri,
            'database_max_retries'    => '-1',
          )
        end

        it 'auth options' do
          identity_uri     = "http://#{service_endpoint}:5000/"
          ks = neutron_config['keystone']
          should contain_class('neutron::server').with(
            'auth_password' => ks.fetch('admin_password'),
            'auth_tenant'   => ks.fetch('admin_tenant', 'services'),
            'auth_region'   => Noop.hiera('region', 'RegionOne'),
            'auth_user'     => ks.fetch('admin_user', 'neutron'),
            'identity_uri'  => identity_uri,
            'auth_uri'      => identity_uri,
          )
        end

        it { should contain_class('neutron::server').with('manage_service' => 'true')}
        it { should contain_class('neutron::server').with('enabled' => 'false')} # bacause server should be started after plugin configured
        it { should contain_class('neutron::server').with('agent_down_time' => '30')}
        it { should contain_class('neutron::server').with('allow_automatic_l3agent_failover' => 'true')}

        it 'dvr' do
          dvr = Noop.hiera_hash('neutron_advanced_configuration', {}).fetch('neutron_dvr', false)
          should contain_class('neutron::server').with('router_distributed' => dvr)
        end

        it 'worker count' do
          fallback_workers = [[processorcount, 2].max, 16].min
          workers = neutron_config.fetch('workers', fallback_workers)
          should contain_class('neutron::server').with(
            'api_workers' => workers,
            'rpc_workers' => workers,
          )
        end

        it 'neutron::server::notifications' do
          auth_api_version    = 'v2.0'
          nova_admin_auth_url = "http://#{service_endpoint}:35357/#{auth_api_version}/"
          nova_endpoint       = Noop.hiera('nova_endpoint', management_vip)
          nova_url            = "http://#{nova_endpoint}:8774/v2"
          nova_hash           = Noop.hiera_hash('nova', {})
          should contain_class('neutron::server::notifications').with(
            'nova_url'               => nova_url,
            'nova_admin_auth_url'    => nova_admin_auth_url,
            'nova_region_name'       => Noop.hiera('region', 'RegionOne'),
            'nova_admin_username'    => nova_hash.fetch('user', 'nova'),
            'nova_admin_tenant_name' => nova_hash.fetch('tenant', 'services'),
            'nova_admin_password'    => nova_hash.fetch('user_password'),
          )
        end

        it { should contain_service('neutron-server').with(
          'ensure' => 'stopped',
          'enable' => 'false',
        )}

      end
    end
  end
  test_ubuntu_and_centos manifest
end
