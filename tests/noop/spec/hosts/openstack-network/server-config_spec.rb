require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-config.pp'

describe manifest do
  shared_examples 'catalog' do
    if (Noop.hiera('use_neutron') == true and Noop.hiera('role') =~ /controller/)
      let(:network_scheme) do
        Noop.hiera_hash('network_scheme', {})
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

      let(:neutron_plugin_ml2_override_resources) do
        configuration_override.fetch('neutron_plugin_ml2', {})
      end

      let(:memcached_servers) { Noop.hiera 'memcached_servers' }

      context 'with Neutron-server' do
        workers_max      = Noop.hiera 'workers_max'
        neutron_config   = Noop.hiera_hash('neutron_config')
        management_vip   = Noop.hiera('management_vip')
        service_endpoint = Noop.hiera('service_endpoint', management_vip)
        l3_ha            = Noop.hiera_hash('neutron_advanced_configuration', {}).fetch('neutron_l3_ha', false)
        extension_drivers = ['port_security']
        segmentation_type = neutron_config.fetch('L2',{}).fetch('segmentation_type')
        pnets = neutron_config.fetch('L2',{}).fetch('phys_nets',{})
        role = Noop.hiera('role')
        adv_neutron_config = Noop.hiera_hash('neutron_advanced_configuration')
        dvr = adv_neutron_config.fetch('neutron_dvr', false)

        if segmentation_type == 'vlan'
          network_type   = 'vlan'
          network_vlan_ranges_physnet2 = pnets.fetch('physnet2',{}).fetch('vlan_range')
          if role =~ /controller/ and !dvr
            physnets_array = ["physnet1:#{pnets['physnet1']['bridge']}", "physnet2:#{pnets['physnet2']['bridge']}"]
            network_vlan_ranges = ["physnet1", "physnet2:#{network_vlan_ranges_physnet2}"]
          else
            physnets_array = ["physnet2:#{pnets['physnet2']['bridge']}"]
            network_vlan_ranges = ["physnet2:#{network_vlan_ranges_physnet2}"]
          end
          tunnel_id_ranges  = []
          overlay_net_mtu = '1500'
          tunnel_types = []
          if pnets['physnet-ironic']
            physnets_array << "physnet-ironic:#{pnets['physnet-ironic']['bridge']}"
            network_vlan_ranges << 'physnet-ironic'
          end
        else
          if role == 'compute' and !dvr
            physnets_array = []
          else
            physnets_array = ["physnet1:#{pnets['physnet1']['bridge']}"]
          end
          network_type   = 'vxlan'
          network_vlan_ranges = []
          tunnel_id_ranges  = [neutron_config.fetch('L2',{}).fetch('tunnel_id_ranges')]
          overlay_net_mtu = '1450'
          tunnel_types    = [network_type]
        end

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

        it 'should configure keystone_authtoken memcached_servers' do
          should contain_neutron_server('keystone_authtoken/memcached_servers').with_value(memcached_servers.join(','))
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
        it { should contain_class('neutron::server').with('enabled' => 'true')}
        it { should contain_class('neutron::server').with('agent_down_time' => '30')}

        it 'dvr' do
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

        it 'should declare neutron::server class with 4 processess on 4 CPU & 32G system' do
          should contain_class('neutron::server').with(
            'api_workers' => '4',
            'rpc_workers' => '4',
          )
        end

        it 'worker count' do
          fallback_workers = [[facts[:processorcount].to_i, 2].max, workers_max.to_i].min
          workers = neutron_config.fetch('workers', fallback_workers)
          should contain_class('neutron::server').with(
            'api_workers' => workers,
            'rpc_workers' => workers,
          )
        end

        l2_population = adv_neutron_config.fetch('neutron_l2_pop', false)

        if l2_population
          default_mechanism_drivers = 'openvswitch,l2population'
        else
          default_mechanism_drivers = 'openvswitch'
        end

        it { should contain_service('neutron-server').with(
          'enable' => 'true',
        )}

        it { should contain_class('neutron::plugins::ml2').with(
          'enable_security_group' => 'true',
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'flat_networks' => '*',
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'type_drivers' => ['local', 'flat', 'vlan', 'gre', 'vxlan'],
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'tenant_network_types' => ['flat', network_type],
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'mechanism_drivers' => neutron_config.fetch('L2', {}).fetch('mechanism_drivers', default_mechanism_drivers).split(',')
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'network_vlan_ranges' => network_vlan_ranges,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'tunnel_id_ranges' => tunnel_id_ranges,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'vni_ranges' => tunnel_id_ranges,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'vxlan_group' => '224.0.0.1',
        )}
        it {
          if segmentation_type == 'vlan'
            physical_network_mtus = Noop.puppet_function('generate_physnet_mtus', Noop.hiera_hash('neutron_config'), network_scheme, { 'do_floating' => true, 'do_tenant' => true, 'do_provider' => false })
          else
            physical_network_mtus = Noop.puppet_function('generate_physnet_mtus', Noop.hiera_hash('neutron_config'), network_scheme, { 'do_floating' => true, 'do_tenant' => false, 'do_provider' => false })
          end
          should contain_class('neutron::plugins::ml2').with(
          'physical_network_mtus' => physical_network_mtus,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'path_mtu' => overlay_net_mtu,
        )}
        it { should contain_class('neutron::plugins::ml2').with(
          'extension_drivers' => extension_drivers,
        )}

        it 'neutron config should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_config').with(:data => neutron_config_override_resources)
        end

        it 'neutron api config should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_api_config').with(:data => neutron_api_config_override_resources)
        end

        it 'neutron plugin ml2 should be modified by override_resources' do
          is_expected.to contain_override_resources('neutron_plugin_ml2').with(:data => neutron_plugin_ml2_override_resources)
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
          neutron_plugin_ml2_override_resources.each do |title, params|
            params['value'] = 'True' if params['value'].is_a? TrueClass
            expect(ral_catalog).to contain_neutron_plugin_ml2(title).with(params)
          end
        end

      end
    end
  end
  test_ubuntu_and_centos manifest
end
