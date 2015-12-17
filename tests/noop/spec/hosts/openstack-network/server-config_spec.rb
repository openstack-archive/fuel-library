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

      let(:configuration_override) do
        Noop.hiera_structure 'configuration'
      end

      let(:neutron_config_override_resources) do
        configuration_override.fetch('neutron_config', {})
      end

      let(:neutron_api_config_override_resources) do
        configuration_override.fetch('neutron_api_config', {})
      end

      context 'with Neutron-server' do
        neutron_config   = Noop.hiera_hash('neutron_config')
        management_vip   = Noop.hiera('management_vip')
        service_endpoint = Noop.hiera('service_endpoint', management_vip)
        l3_ha            = Noop.hiera_hash('neutron_advanced_configuration', {}).fetch('neutron_l3_ha', false)

        it 'database options' do
          database_vip        = Noop.hiera('database_vip')
          db_password = neutron_config.fetch('database', {}).fetch('passwd')
          db_user     = neutron_config.fetch('database', {}).fetch('user', 'neutron')
          db_name     = neutron_config.fetch('database', {}).fetch('name', 'neutron')
          db_host     = neutron_config.fetch('database', {}).fetch('host', database_vip)
          if facts[:os_package_type] == 'debian'
            extra_params = '?read_timeout=60'
          else
            extra_params = ''
          end
          db_connection = "mysql://#{db_user}:#{db_password}@#{db_host}/#{db_name}#{extra_params}"

          should contain_class('neutron::server').with(
            'sync_db'                 => 'false',
            'database_retry_interval' => '2',
            'database_connection'     => db_connection,
            'database_max_retries'    => '-1',
          )
        end

        if Noop.hiera_structure('use_ssl', false)
          context 'with overridden TLS for internal endpoints' do
            internal_auth_protocol = 'https'
            internal_auth_endpoint = Noop.hiera_structure('use_ssl/keystone_internal_hostname')

            it 'should have correct auth options' do
              identity_uri     = "#{internal_auth_protocol}://#{internal_auth_endpoint}:5000/"
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

            admin_auth_protocol = 'https'
            admin_auth_endpoint = Noop.hiera_structure('use_ssl/keystone_admin_hostname')
            nova_auth_protocol  = 'https'
            internal_nova_endpoint = Noop.hiera_structure('use_ssl/nova_internal_hostname')
            it 'should declare class neutron::server::notifications with TLS endpoints' do
              nova_admin_auth_url = "#{admin_auth_protocol}://#{admin_auth_endpoint}:35357/"
              nova_url            = "#{nova_auth_protocol}://#{internal_nova_endpoint}:8774/v2"
              nova_hash           = Noop.hiera_hash('nova', {})
              should contain_class('neutron::server::notifications').with(
                'nova_url'    => nova_url,
                'auth_url'    => nova_admin_auth_url,
                'region_name' => Noop.hiera('region', 'RegionOne'),
                'username'    => nova_hash.fetch('user', 'nova'),
                'tenant_name' => nova_hash.fetch('tenant', 'services'),
                'password'    => nova_hash.fetch('user_password'),
              )
            end
          end
        else
          context 'without overridden TLS for internal endpoints' do
            it 'should have correct auth options' do
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

            it 'should declare neutron::server::notifications without TLS endpoints' do
              nova_admin_auth_url = "http://#{service_endpoint}:35357/"
              nova_endpoint       = Noop.hiera('nova_endpoint', management_vip)
              nova_url            = "http://#{nova_endpoint}:8774/v2"
              nova_hash           = Noop.hiera_hash('nova', {})
              should contain_class('neutron::server::notifications').with(
                'nova_url'    => nova_url,
                'auth_url'    => nova_admin_auth_url,
                'region_name' => Noop.hiera('region', 'RegionOne'),
                'username'    => nova_hash.fetch('user', 'nova'),
                'tenant_name' => nova_hash.fetch('tenant', 'services'),
                'password'    => nova_hash.fetch('user_password'),
              )
            end
          end
        end

        it { should contain_class('neutron::server').with('manage_service' => 'true')}
        it { should contain_class('neutron::server').with('enabled' => 'false')} # bacause server should be started after plugin configured
        it { should contain_class('neutron::server').with('agent_down_time' => '30')}

        it 'dvr' do
          dvr = Noop.hiera_hash('neutron_advanced_configuration', {}).fetch('neutron_dvr', false)
          should contain_class('neutron::server').with('router_distributed' => dvr)
        end

        if l3_ha
          it 'l3_ha_enabled' do
            should contain_class('neutron::server').with(
              'l3_ha'                            => true,
              'allow_automatic_l3agent_failover' => false,
              'min_l3_agents_per_router'         => 2,
              'max_l3_agents_per_router'         => 0,
            )
          end
        else
          it 'l3_ha_disabled' do
            should contain_class('neutron::server').with(
              'l3_ha'                            => false,
              'allow_automatic_l3agent_failover' => true,
            )
          end
        end

        it 'worker count' do
          fallback_workers = [[processorcount, 2].max, 16].min
          workers = neutron_config.fetch('workers', fallback_workers)
          should contain_class('neutron::server').with(
            'api_workers' => workers,
            'rpc_workers' => workers,
          )
        end

        it { should contain_service('neutron-server').with(
          'ensure' => 'stopped',
          'enable' => 'false',
        )}

        it 'neutron config should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_config').with(:data => neutron_config_override_resources)
        end

        it 'neutron api config should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_api_config').with(:data => neutron_api_config_override_resources)
        end

        it 'should use "override_resources" to update the catalog' do
          ral_catalog = Noop.create_ral_catalog self
          neutron_config_override_resources.each do |title, params|
            params['value'] = 'True' if params['value'].is_a? TrueClass
            expect(ral_catalog).to contain_neutron_config(title).with(params)
          end
          neutron_api_config_override_resources.each do |title, params|
            params['value'] = 'True' if params['value'].is_a? TrueClass
            expect(ral_catalog).to contain_neutron_api_config(title).with(params)
          end
        end

      end
    end
  end
  test_ubuntu_and_centos manifest
end
