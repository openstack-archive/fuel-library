# ROLE: primary-controller
# ROLE: controller

require 'spec_helper'
require 'shared-examples'
manifest = 'openstack-network/server-config.pp'

describe manifest do

  before(:each) do
    Noop.puppet_function_load :is_pkg_installed
    MockFunction.new(:is_pkg_installed) do |function|
      allow(function).to receive(:call).and_return false
    end
  end

  shared_examples 'catalog' do
    let(:network_scheme) do
      Noop.hiera_hash('network_scheme', {})
    end

    let(:prepare) do
      Noop.puppet_function 'prepare_network_config', network_scheme
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

    context 'with Neutron-server' do
      neutron_config        = Noop.hiera_hash('neutron_config')
      neutron_server_enable = neutron_config.fetch('neutron_server_enable', true)
      database_vip          = Noop.hiera('database_vip')
      management_vip        = Noop.hiera('management_vip')
      service_endpoint      = Noop.hiera('service_endpoint', management_vip)
      nova_endpoint         = Noop.hiera('nova_endpoint', management_vip)
      nova_hash             = Noop.hiera_hash('nova', {})
      pci_vendor_devs       = neutron_config.fetch('supported_pci_vendor_devs', false)

      neutron_primary_controller_roles = Noop.hiera('neutron_primary_controller_roles', ['primary-controller'])
      neutron_compute_roles            = Noop.hiera('neutron_compute_nodes', ['compute'])
      primary_controller               = Noop.puppet_function 'roles_include', neutron_primary_controller_roles
      compute                          = Noop.puppet_function 'roles_include', neutron_compute_roles

      it 'Configure database options for neutron::server' do
        sync_db     = Noop.hiera('primary_controller')
        db_type     = neutron_config.fetch('database', {}).fetch('type', 'mysql+pymysql')
        db_password = neutron_config.fetch('database', {}).fetch('passwd')
        db_user     = neutron_config.fetch('database', {}).fetch('user', 'neutron')
        db_name     = neutron_config.fetch('database', {}).fetch('name', 'neutron')
        db_host     = neutron_config.fetch('database', {}).fetch('host', database_vip)

        if facts[:os_package_type] == 'debian'
          extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
        else
          extra_params = { 'charset' => 'utf8' }
        end
        db_connection = Noop.puppet_function 'os_database_connection', {
          'dialect'  => db_type,
          'host'     => db_host,
          'database' => db_name,
          'username' => db_user,
          'password' => db_password,
          'extra'    => extra_params }

        should contain_class('neutron::server').with(
          'sync_db'                 => sync_db,
          'database_retry_interval' => '2',
          'database_connection'     => db_connection,
          'database_max_retries'    => Noop.hiera('max_retries'),
          'database_idle_timeout'   => Noop.hiera('idle_timeout'),
          'database_max_pool_size'  => Noop.hiera('max_pool_size'),
          'database_max_overflow'   => Noop.hiera('max_overflow'),
        )
      end

      if pci_vendor_devs
        use_sriov       = true
        ml2_sriov_value = 'set DAEMON_ARGS \'"$DAEMON_ARGS --config-file /etc/neutron/plugins/ml2/ml2_conf_sriov.ini"\''
      else
        use_sriov       = false
        ml2_sriov_value = 'rm DAEMON_ARGS'
      end

      ks                 = neutron_config['keystone']
      password           = ks.fetch('admin_password')
      username           = ks.fetch('admin_user', 'neutron')
      project_name       = ks.fetch('admin_tenant', 'services')
      region_name        = Noop.hiera('region', 'RegionOne')
      auth_endpoint_type = 'internalURL'
      memcached_servers  = Noop.hiera 'memcached_servers'

      ssl_hash               = Noop.hiera_hash('use_ssl', {})
      internal_auth_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','protocol', 'http'
      internal_auth_endpoint = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','internal','hostname', [service_endpoint, management_vip]

      admin_auth_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','protocol', 'http'
      admin_auth_endpoint = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'keystone','admin','hostname', [service_endpoint, management_vip]

      nova_internal_protocol = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'nova','internal','protocol', 'http'
      nova_internal_endpoint = Noop.puppet_function 'get_ssl_property',ssl_hash,{},'nova','internal','hostname', nova_endpoint

      auth_api_version    = 'v2.0'
      auth_url            = "#{internal_auth_protocol}://#{internal_auth_endpoint}:35357/"
      auth_uri            = "#{internal_auth_protocol}://#{internal_auth_endpoint}:5000/"
      nova_admin_auth_url = "#{admin_auth_protocol}://#{admin_auth_endpoint}:35357/"

      workers_max = Noop.hiera('workers_max', '16')

      it {
        service_workers =  neutron_config.fetch('workers', [[facts[:processorcount].to_i, 1].max, workers_max.to_i].min)
        should contain_class('neutron::server').with(
          'api_workers' => service_workers,
          'rpc_workers' => service_workers,)
      }

      neutron_advanced_config = Noop.hiera_hash('neutron_advanced_configuration', {})
      l2_population           = neutron_advanced_config.fetch('neutron_l2_pop', false)
      dvr                     = neutron_advanced_config.fetch('neutron_dvr', false)
      l3_ha                   = neutron_advanced_config.fetch('neutron_l3_ha', false)
      it {
        if l3_ha
          l3agent_failover = false
        else
          l3agent_failover = true
        end

        should contain_class('neutron::server').with(
          'allow_automatic_l3agent_failover' => l3agent_failover,)
      }
      enable_qos = neutron_advanced_config.fetch('neutron_qos', false)

      it {
        if enable_qos
          qos_notification_drivers = 'message_queue'
          extension_drivers = ['port_security', 'qos']

          should contain_class('neutron::server').with(
            'qos_notification_drivers' => qos_notification_drivers,)
        else
          extension_drivers = ['port_security']
        end

        should contain_class('neutron::plugins::ml2').with(
          'extension_drivers' => extension_drivers,)
      }

      nova_auth_user            = nova_hash.fetch('user', 'nova')
      nova_auth_password        = nova_hash['user_password']
      nova_auth_tenant          = nova_hash.fetch('tenant', 'services')
      type_drivers              = ['local', 'flat', 'vlan', 'gre', 'vxlan']
      default_mechanism_drivers = ['openvswitch']

      if l2_population
        l2_population_mech_driver = ['l2population']
      else
        l2_population_mech_driver = []
      end

      if use_sriov
        sriov_mech_driver = ['sriovnicswitch']
      else
        sriov_mech_driver = []
      end

      mechanism_drivers_default = default_mechanism_drivers+l2_population_mech_driver+sriov_mech_driver
      mechanism_drivers         = neutron_config.fetch('L2',{}).fetch('mechanism_drivers', mechanism_drivers_default)
      flat_networks             = ['*']
      segmentation_type         = neutron_config.fetch('L2',{}).fetch('segmentation_type')

      _path_mtu = neutron_config.fetch('L2',{}).fetch('path_mtu', false)

      role = Noop.hiera('role')
      if role == 'compute' and !dvr
        do_floating = false
      else
        do_floating = true
      end

      it {
        if segmentation_type == 'vlan'
          physical_network_mtus = Noop.puppet_function('generate_physnet_mtus', neutron_config, network_scheme, { 'do_floating' => do_floating, 'do_tenant' => true, 'do_provider' => false })
          if _path_mtu
            path_mtu = _path_mtu
            should contain_class('neutron::plugins::ml2').with(
           'path_mtu' => path_mtu,)
          end
          network_vlan_ranges = Noop.puppet_function('generate_physnet_vlan_ranges', neutron_config, Noop.hiera_hash('network_scheme', {}),
            { 'do_floating' => do_floating,
              'do_tenant'   => true,
              'do_provider' => false })
          tunnel_id_ranges = []

        else
          physical_network_mtus = Noop.puppet_function('generate_physnet_mtus', neutron_config, network_scheme,
            { 'do_floating' => do_floating,
              'do_tenant'   => false,
              'do_provider' => false })

          iface = Noop.puppet_function 'get_network_role_property', 'neutron/mesh', 'phys_dev'
          if _path_mtu
            path_mtu = _path_mtu
          else
            path_mtu = Noop.puppet_function 'pick', Noop.puppet_function('get_transformation_property','mtu', iface[0]), '1500'
          end

          network_vlan_ranges = []
          tunnel_id_ranges = neutron_config.fetch('L2',{}).fetch('tunnel_id_ranges')
          should contain_class('neutron::plugins::ml2').with(
          'path_mtu' => path_mtu,)
        end
        should contain_class('neutron::plugins::ml2').with(
        'physical_network_mtus' => physical_network_mtus,
        'network_vlan_ranges'   => network_vlan_ranges,
        'tunnel_id_ranges'      => tunnel_id_ranges,
        'vni_ranges'            => tunnel_id_ranges,)
      }

      if segmentation_type == 'vlan'
        network_type = 'vlan'
      else
        if segmentation_type == 'gre'
          network_type = 'gre'
        else
          network_type = 'vxlan'
        end
      end

      vxlan_group = '224.0.0.1'
      tenant_network_types  = ['flat', network_type]

      it 'sets up pci_vendor_devs for neutron::plugins::ml2' do
        if pci_vendor_devs
          should contain_class('neutron::plugins::ml2').with(
           'physical_network_mtus' => physical_network_mtus,)
        end
      end

      it 'sets up ml2_sriov_config for neutron-server' do
        if role != 'compute' and facts[:osfamily] == 'Debian'
          should contain_augeas('/etc/default/neutron-server:ml2_sriov_config').with(
            'context' => '/files/etc/default/neutron-server',
            'changes' => ml2_sriov_value,
          ).that_notifies('Service[neutron-server]')
          should contain_class('neutron::plugins::ml2').that_comes_before('Augeas[/etc/default/neutron-server:ml2_sriov_config]')
        end
      end

      it 'should configure neutron::plugins::ml2' do
        should contain_class('neutron::plugins::ml2').with(
          'type_drivers'          => type_drivers,
          'tenant_network_types'  => tenant_network_types,
          'mechanism_drivers'     => mechanism_drivers,
          'flat_networks'         => flat_networks,
          'vxlan_group'           => vxlan_group,
          'sriov_agent_required'  => use_sriov,
          'enable_security_group' => true,
          'firewall_driver'       => 'neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver',
        )
      end

      it 'should have correct auth options' do
        should contain_class('neutron::server').with(
          'password'     => password,
          'project_name' => project_name,
          'region_name'  => region_name,
          'username'     => username,
          'auth_url'     => auth_url,
          'auth_uri'     => auth_uri,)
      end

      it 'should have agent related settings' do
        should contain_class('neutron::server').with(
          'agent_down_time'          => neutron_config['neutron_agent_down_time'],
          'l3_ha'                    => l3_ha,
          'min_l3_agents_per_router' => '2',
          'max_l3_agents_per_router' => '0',)
      end

      it {
        should contain_class('neutron::server').with(
          'router_distributed' => dvr,
          'enabled'            => true,
          'manage_service'     => true,
          'memcached_servers'  => memcached_servers,)
      }

      it 'should configure neutron::server::notifications' do
        should contain_class('neutron::server::notifications').with(
         'auth_url'     => nova_admin_auth_url,
         'region_name'  => region_name,
         'username'     => nova_auth_user,
         'project_name' => nova_auth_tenant,
         'password'     => nova_auth_password,
         )
      end

      it 'should contain package neutron' do
        should contain_package('neutron').with(
          'name'   => 'binutils',
          'ensure' => 'installed',)
      end
    end
  end
  test_ubuntu_and_centos manifest
end
