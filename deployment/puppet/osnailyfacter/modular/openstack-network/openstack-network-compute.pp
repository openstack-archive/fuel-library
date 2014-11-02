notice('MODULAR: openstack-network-compute.pp')

$use_neutron                    = hiera('use_neutron', false)
$nova_hash                      = hiera('nova', {})
$internal_address               = hiera('internal_address')
$service_endpoint               = hiera('management_vip')
$public_int                     = hiera('public_int', undef)
$auto_assign_floating_ip        = hiera('auto_assign_floating_ip', false)
$controllers                    = hiera('controllers')
$controller_internal_addresses  = nodes_to_hash($controllers,'name','internal_address')
$controller_nodes               = ipsort(values($controller_internal_addresses))
$rabbit_hash                    = hiera('rabbit_hash', {})

$floating_hash = {}

# amqp settings
if $internal_address in $controller_nodes {
  # prefer local MQ broker if it exists on this node
  $amqp_nodes = concat(['127.0.0.1'], fqdn_rotate(delete($controller_nodes, $internal_address)))
} else {
  $amqp_nodes = fqdn_rotate($controller_nodes)
}
$amqp_port = '5673'
$amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.join ',' %>")

class { 'l23network' :
  use_ovs => $use_neutron
}

if $use_neutron {
  $network_provider      = 'neutron'
  $novanetwork_params    = {}
  $neutron_config        = hiera('quantum_settings')
  $neutron_db_password   = $neutron_config['database']['passwd']
  $neutron_user_password = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac              = $neutron_config['L2']['base_mac']
} else {
  $network_provider   = 'nova'
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
}
$fixed_range = $use_neutron ? { true=>false, default=>hiera('fixed_network_range')}

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
$public_interface = $public_int ? { undef=>'', default=>$public_int}
$libvirt_vif_driver = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'
$neutron_integration_bridge = 'br-int'
$neutron_settings = $neutron_config

# if the compute node should be configured as a multi-host
# compute installation
if $network_provider == 'nova' {

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
      ensure_package       => $openstack_version['nova'],
      enabled              => true,
      admin_tenant_name    => 'services',
      admin_user           => 'nova',
      admin_password       => $nova_hash[user_password],
      enabled_apis         => $enabled_apis,
      api_bind_address     => $internal_address,
      auth_host            => $service_endpoint,
      ratelimits           => hiera('nova_rate_limits'),
      # NOTE(bogdando) 1 api worker for compute node is enough
      osapi_compute_workers => 1,
    }

    if($::operatingsystem == 'Ubuntu') {
      tweaks::ubuntu_service_override { 'nova-api':
        package_name => 'nova-api',
      }
    }

    nova_config {
      'DEFAULT/multi_host':      value => 'True';
      'DEFAULT/send_arp_for_ha': value => 'True';
      'DEFAULT/metadata_host':   value => $internal_address;
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
      'DEFAULT/multi_host':      value => 'False';
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



} else {
  # Neutron
  include ::nova::params

  service { 'libvirt' :
    ensure   => running,
    enable   => true,
    name     => $::nova::params::libvirt_service_name,
    provider => $::nova::params::special_service_provider,
  }

  # script called by qemu needs to manipulate the tap device
  file { '/etc/libvirt/qemu.conf':
    ensure => present,
    notify => Service['libvirt'],
    source => 'puppet:///modules/nova/libvirt_qemu.conf',
  }

  file_line { 'no_qemu_selinux':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'security_driver="none"',
    require => File['/etc/libvirt/qemu.conf'],
    notify  => Service['libvirt']
  }

  class { 'nova::compute::neutron':
    libvirt_vif_driver => $libvirt_vif_driver,
  }

  nova_config {
    'DEFAULT/linuxnet_interface_driver':       value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
    'DEFAULT/linuxnet_ovs_integration_bridge': value => $neutron_integration_bridge;
  }

  augeas { 'sysctl-net.bridge.bridge-nf-call-arptables':
    context => '/files/etc/sysctl.conf',
    changes => "set net.bridge.bridge-nf-call-arptables '1'",
    before  => Service['libvirt'],
  }
  augeas { 'sysctl-net.bridge.bridge-nf-call-iptables':
    context => '/files/etc/sysctl.conf',
    changes => "set net.bridge.bridge-nf-call-iptables '1'",
    before  => Service['libvirt'],
  }
  augeas { 'sysctl-net.bridge.bridge-nf-call-ip6tables':
    context => '/files/etc/sysctl.conf',
    changes => "set net.bridge.bridge-nf-call-ip6tables '1'",
    before  => Service['libvirt'],
  }

  # We need to restart nova-compute service in orderto apply new settings
  service { 'nova-compute':
    ensure => 'running',
    name   => $::nova::params::compute_service_name,
  }
  Nova_config<| |> ~> Service['nova-compute']
}

####### Disable upstart startup on install #######
if($::operatingsystem == 'Ubuntu') {
  tweaks::ubuntu_service_override { 'nova-network':
    package_name => 'nova-network',
  }
}

######## [Nova|Neutron] Network ########
if $network_provider == 'neutron' {

  # FIXME(xarses) Nearly everything between here and the class
  # should be moved into osnaily or nailgun but will stay here
  # in the interim.

  $pnets = $neutron_settings['L2']['phys_nets']
  if $pnets['physnet1'] {
    $physnet1 = "physnet1:${pnets['physnet1']['bridge']}"
    notify{ $physnet1:}
  }
  if $pnets['physnet2'] {
    $physnet2 = "physnet2:${pnets['physnet2']['bridge']}"
    notify{ $physnet2:}
    if $pnets['physnet2']['vlan_range'] {
      $vlan_range = ["physnet2:${pnets['physnet2']['vlan_range']}"]
      $fallback = split($pnets['physnet2']['vlan_range'], ':')
      notify{ $vlan_range:}
    }
  } else {
    $vlan_range = []
  }

  if $physnet1 and $physnet2 {
    $bridge_mappings = [$physnet1, $physnet2]
  } elsif $physnet1 {
    $bridge_mappings = [$physnet1]
  } elsif $physnet2 {
    $bridge_mappings = [$physnet2]
  } else {
    $bridge_mappings = []
  }

  if $neutron_settings['L2']['tunnel_id_ranges'] {
    $enable_tunneling = true
    $tunnel_id_ranges = [$neutron_settings['L2']['tunnel_id_ranges']]
  } else {
    $enable_tunneling = false
    $tunnel_id_ranges = []
  }
  notify{ $tunnel_id_ranges:}
  if $neutron_settings['L2']['mechanism_drivers'] {
      $mechanism_drivers = split($neutron_settings['L2']['mechanism_drivers'], ',')
  } else {
      $mechanism_drivers = ['openvswitch', 'l2population']
  }

  if $neutron_settings['L2']['provider'] == 'ovs' {
    $core_plugin      = 'openvswitch'
    $agent            = 'ovs'
  } else {
    # by default we use ML2 plugin
    $core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
    $agent            = 'ml2-ovs'
  }

  #   hard-coded only for testing
  #   will be removed when this option will be available
  #   $dvr = $neutron_settings['DVR']
  $dvr = true
  if $dvr {
    $agents = [$agent, 'l3' , 'metadata']
  }
  else {
    $agents = [$agent]
  }
}

class { 'openstack::network':
  network_provider  => $network_provider,
  agents            => $agents,
  nova_neutron      => true,

  base_mac          => $base_mac,
  core_plugin       => $core_plugin,
  service_plugins   => undef,
  dvr               => $dvr,

  # ovs
  mechanism_drivers   => $mechanism_drivers,
  local_ip            => $internal_address,
  bridge_mappings     => $bridge_mappings,
  network_vlan_ranges => $vlan_range,
  enable_tunneling    => $enable_tunneling,
  tunnel_id_ranges    => $tunnel_id_ranges,

  verbose             => true,
  debug               => hiera('debug', true),
  use_syslog          => hiera('use_syslog', true),
  syslog_log_facility => hiera('syslog_log_facility_neutron', 'LOG_LOCAL4'),

  # queue settings
  queue_provider => hiera('queue_provider', 'rabbitmq'),
  amqp_hosts     => [$amqp_hosts],
  amqp_user      => $rabbit_hash['user'],
  amqp_password  => $rabbit_hash['password'],

  # keystone
  admin_password => $neutron_user_password,
  auth_url       => "http://${service_endpoint}:35357/v2.0",
  neutron_url    => "http://${service_endpoint}:9696",

  # metadata
  shared_secret   => $neutron_metadata_proxy_secret,
  metadata_ip     => $service_endpoint,

  integration_bridge => $neutron_integration_bridge,

  # nova settings
  private_interface => $use_neutron ? { true=>false, default=>hiera('private_int')},
  public_interface  => hiera('public_int', undef),
  fixed_range       => $use_neutron ? { true =>false, default =>hiera('fixed_network_range')},
  floating_range    => $use_neutron ? { true =>$floating_hash, default  =>false},
  network_manager   => hiera('network_manager', undef),
  network_config    => hiera('network_config', {}),
  create_networks   => $create_networks,
  num_networks      => hiera('num_networks', undef),
  network_size      => hiera('network_size', undef),
  nameservers       => hiera('dns_nameservers', undef),
  enable_nova_net   => $enable_network_service,
}
