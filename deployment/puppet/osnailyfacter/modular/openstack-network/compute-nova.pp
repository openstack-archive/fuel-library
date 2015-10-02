notice('MODULAR: openstack-network/compute-nova.pp')

$use_neutron = hiera('use_neutron', false)

if ! $use_neutron {

  $network_scheme                 = hiera('network_scheme', { })
  prepare_network_config($network_scheme)
  $use_neutron                    = hiera('use_neutron', false)
  $nova_hash                      = hiera_hash('nova_hash', { })
  $bind_address                   = get_network_role_property('nova/api', 'ipaddr')
  $management_vip                 = hiera('management_vip')
  $service_endpoint               = hiera('service_endpoint')
  $public_int                     = get_network_role_property('ex', 'interface') # will be removed eventually with nova-network code
  $auto_assign_floating_ip        = hiera('auto_assign_floating_ip', false)
  $rabbit_hash                    = hiera_hash('rabbit_hash', { })
  $neutron_endpoint               = hiera('neutron_endpoint', $management_vip)
  $region                         = hiera('region', 'RegionOne')
  $openstack_network_hash         = hiera_hash('openstack_network', { })

  $floating_hash = { }

  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = { }
  $novanetwork_params = hiera('novanetwork_parameters')

  $fixed_range = $use_neutron ? { true=>false, default=>hiera('fixed_network_range') }

  if hiera('use_vcenter', false) {
    $multi_host = false
  } else {
    $multi_host = true
  }

  $openstack_version = {
    'keystone'   => 'installed',
    'glance'     => 'installed',
    'horizon'    => 'installed',
    'nova'       => 'installed',
    'novncproxy' => 'installed',
    'cinder'     => 'installed',
  }

  $enabled_apis = 'metadata'
  $public_interface = $public_int ? { undef=>'', default=>$public_int }
  $libvirt_vif_driver = pick($nova_hash['libvirt_vif_driver'], 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver')
  $neutron_integration_bridge = 'br-int'
  $neutron_settings = $neutron_config


  if ! $fixed_range {
    fail('Must specify the fixed range when using nova-networks')
  }

  if $multi_host {
    include keystone::python

    Nova_config<| |> -> Service['nova-network']

    case $::osfamily {
      'RedHat': {
        $pymemcache_package_name      = 'python-memcached'
      }
      'Debian': {
        $pymemcache_package_name      = 'python-memcache'
      }
      default: {
        fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem},\
              module ${module_name} only support osfamily RedHat and Debian")
      }
    }
    if !defined(Package[$pymemcache_package_name]) {
      package { $pymemcache_package_name:
        ensure => present,
      } ->
      Nova::Generic_service <| title == 'api' |>
    }

    class { 'nova::api':
      ensure_package        => $openstack_version['nova'],
      enabled               => true,
      admin_tenant_name     => 'services',
      admin_user            => 'nova',
      admin_password        => $nova_hash[user_password],
      enabled_apis          => $enabled_apis,
      api_bind_address      => $bind_address,
      ratelimits            => hiera('nova_rate_limits'),
    # NOTE(bogdando) 1 api worker for compute node is enough
      osapi_compute_workers => 1,
    }

    if($::operatingsystem == 'Ubuntu') {
      tweaks::ubuntu_service_override { 'nova-api':
        package_name => 'nova-api',
      }
    }

    nova_config {
      'DEFAULT/multi_host': value => 'True';
      'DEFAULT/send_arp_for_ha': value => 'True';
      'DEFAULT/metadata_host': value => $bind_address;
    }

    if ! $public_interface {
      fail('public_interface must be defined for multi host compute nodes')
    }

    $enable_network_service = true

    if $auto_assign_floating_ip {
      nova_config { 'DEFAULT/auto_assign_floating_ip': value => 'True' }
    }
  } else {
    $enable_network_service = false

    nova_config {
      'DEFAULT/multi_host': value => 'False';
      'DEFAULT/send_arp_for_ha': value => 'False';
    }
  }

# From legacy network.pp
# I don't think this is applicable to Folsom...
# If it is, the details will need changed. -jt
  if hiera('network_manager', undef) == 'nova.network.neutron.manager.NeutronManager' {
    $parameters = { fixed_range      => $fixed_range,
      public_interface => $public_interface,
    }
    $resource_parameters = merge($_config_overrides, $parameters)
    $neutron_resource = { 'nova::network::neutron' => $resource_parameters }
    create_resources('class', $neutron_resource)
  }

# Stub for networking-refresh that is needed by Nova::Network/Nova::Generic_service[network]
# We do not need it due to l23network is doing all stuff
# BTW '/sbin/ifdown -a ; /sbin/ifup -a' does not work on CentOS
  exec { 'networking-refresh':
    command     => '/bin/echo "networking-refresh has been refreshed"',
    refreshonly => true,
  }

# Stubs for nova_paste_api_ini
  exec { 'post-nova_config':
    command     => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }
# Stubs for nova_network
  file { '/etc/nova/nova.conf':
    ensure => 'present',
  }
# Stubs for nova-api
  package { 'nova-common':
    name   => 'binutils',
    ensure => 'installed',
  }

####### Disable upstart startup on install #######
  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-network':
      package_name => 'nova-network',
    }
  }

  class { 'openstack::network':
    network_provider     => $network_provider,
    agents               => $agents,
    nova_neutron         => true,
    net_mtu              => pick($phys_net_mtu, 1500),
    network_device_mtu   => $overlay_net_mtu,

    base_mac             => $base_mac,
    core_plugin          => $core_plugin,
    service_plugins      => undef,
    dvr                  => $dvr,
    l2_population        => $l2_population,

  # ovs
    mechanism_drivers    => $mechanism_drivers,
    local_ip             => $tunneling_ip,
    bridge_mappings      => $bridge_mappings,
    network_vlan_ranges  => $vlan_range,
    enable_tunneling     => $enable_tunneling,
    tunnel_id_ranges     => $tunnel_id_ranges,
    vni_ranges           => $tunnel_id_ranges,
    tunnel_types         => $tunnel_types,
    tenant_network_types => $tenant_network_types,

    verbose              => pick($openstack_network_hash['verbose'], true),
    debug                => pick($openstack_network_hash['debug'], hiera('debug', true)),
    use_syslog           => hiera('use_syslog', true),
    use_stderr           => hiera('use_stderr', false),
    syslog_log_facility  => hiera('syslog_log_facility_neutron', 'LOG_LOCAL4'),

  # queue settings
    queue_provider       => hiera('queue_provider', 'rabbitmq'),
    amqp_hosts           => split(hiera('amqp_hosts', ''), ','),
    amqp_user            => $rabbit_hash['user'],
    amqp_password        => $rabbit_hash['password'],

  # keystone
    admin_password       => $neutron_user_password,
    auth_url             => "http://${service_endpoint}:35357/v2.0",
    neutron_url          => "http://${neutron_endpoint}:9696",
    admin_tenant_name    => $keystone_tenant,
    admin_username       => $keystone_user,
    region               => $region,

  # metadata
    shared_secret        => $neutron_metadata_proxy_secret,
    metadata_ip          => $service_endpoint,

    integration_bridge   => $neutron_integration_bridge,

  # nova settings
    private_interface    => $use_neutron ? { true=>false, default=>hiera('private_int') },
    public_interface     => hiera('public_int', undef),
    fixed_range          => $use_neutron ? { true =>false, default =>hiera('fixed_network_range') },
    floating_range       => $use_neutron ? { true =>$floating_hash, default  =>false },
    network_manager      => hiera('network_manager', undef),
    network_config       => hiera('network_config', { }),
    create_networks      => $create_networks,
    num_networks         => hiera('num_networks', undef),
    network_size         => hiera('network_size', undef),
    nameservers          => hiera('dns_nameservers', undef),
    enable_nova_net      => $enable_network_service,
  }

}
