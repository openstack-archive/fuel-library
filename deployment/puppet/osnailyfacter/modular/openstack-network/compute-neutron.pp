notice('MODULAR: openstack-network/compute-neutron.pp')

$use_neutron = hiera('use_neutron', false)

if $use_neutron {

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

  $network_provider              = 'neutron'
  $novanetwork_params            = { }
  $neutron_config                = hiera_hash('quantum_settings')
  $neutron_advanced_config       = hiera_hash('neutron_advanced_configuration', { })
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                      = $neutron_config['L2']['base_mac']
# Neutron Keystone settings
  $neutron_user_password = $neutron_config['keystone']['admin_password']
  $keystone_user         = pick($neutron_config['keystone']['admin_user'], 'neutron')
  $keystone_tenant       = pick($neutron_config['keystone']['admin_tenant'], 'services')

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

# Neutron
  include ::nova::params

  service { 'libvirt' :
    ensure   => running,
    enable   => true,
  # Workaround for bug LP #1469308
  # also service name for Ubuntu and Centos is the same.
    name     => 'libvirtd',
    provider => $::nova::params::special_service_provider,
  }

  exec { 'destroy_libvirt_default_network':
    command => 'virsh net-destroy default',
    onlyif  => 'virsh net-info default | grep -qE "Active:.* yes"',
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    tries   => 3,
    require => Service['libvirt'],
  }

  exec { 'undefine_libvirt_default_network':
    command => 'virsh net-undefine default',
    onlyif  => 'virsh net-info default 2>&1 > /dev/null',
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    tries   => 3,
    require => Exec['destroy_libvirt_default_network'],
  }

  Service['libvirt'] ~> Exec['destroy_libvirt_default_network']

# script called by qemu needs to manipulate the tap device
  file_line { 'clear_emulator_capabilities':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'clear_emulator_capabilities = 0',
    notify  => Service['libvirt']
  }

  file_line { 'no_qemu_selinux':
    path    => '/etc/libvirt/qemu.conf',
    line    => 'security_driver = "none"',
    notify  => Service['libvirt']
  }

  class { 'nova::compute::neutron':
    libvirt_vif_driver => $libvirt_vif_driver,
  }

  nova_config {
    'DEFAULT/linuxnet_interface_driver': value => 'nova.network.linux_net.LinuxOVSInterfaceDriver';
    'DEFAULT/linuxnet_ovs_integration_bridge': value => $neutron_integration_bridge;
    'DEFAULT/network_device_mtu': value => '65000';
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

  if($::operatingsystem == 'Ubuntu') {
    tweaks::ubuntu_service_override { 'nova-network':
      package_name => 'nova-network',
    }
  }


# FIXME(xarses) Nearly everything between here and the class
# should be moved into osnaily or nailgun but will stay here
# in the interim.

  $pnets = $neutron_settings['L2']['phys_nets']
  if $pnets['physnet1'] {
    $physnet1 = "physnet1:${pnets['physnet1']['bridge']}"
    notify{ $physnet1: }
  }
if $pnets['physnet2'] {
  $physnet2 = "physnet2:${pnets['physnet2']['bridge']}"
notify{ $physnet2: }
if $pnets['physnet2']['vlan_range'] {
  $vlan_range = ["physnet2:${pnets['physnet2']['vlan_range']}"]
$fallback = split($pnets['physnet2']['vlan_range'], ':')
notify{ $vlan_range: }
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

$segmentation_type = $neutron_settings['L2']['segmentation_type']

if $segmentation_type != 'vlan' {
# tunneling_mode
  $net_role_property = 'neutron/mesh'
  $tunneling_ip = get_network_role_property($net_role_property, 'ipaddr')
  $iface = get_network_role_property($net_role_property, 'phys_dev')
  $phys_net_mtu = get_transformation_property('mtu', $iface[0])
  $enable_tunneling = true
  if $segmentation_type == 'gre' {
    $network_type = 'gre'
    $mtu_offset = 42
  } else {
    $network_type = 'vxlan'
    $mtu_offset = 50
  }
  if $phys_net_mtu {
    $overlay_net_mtu = $phys_net_mtu - $mtu_offset
  } else {
    $overlay_net_mtu = 1500 - $mtu_offset
  }
  $tunnel_types = [$network_type]
  $tenant_network_types  = ['flat', 'vlan', $network_type]
  $tunnel_id_ranges = [$neutron_config['L2']['tunnel_id_ranges']]
} else {
# vlan_mode
  $net_role_property = 'neutron/private'
  $iface = get_network_role_property($net_role_property, 'phys_dev')
  $phys_net_mtu = get_transformation_property('mtu', $iface[0])
  $overlay_net_mtu = pick($phys_net_mtu, 1500)
  $enable_tunneling = false
  $network_type = 'vlan'
  $tenant_network_types  = ['flat', 'vlan']
  $tunnel_types = []
  $tunneling_ip = false
  $tunnel_id_ranges = []
}

notify{ $tunnel_id_ranges: }
if $neutron_settings['L2']['mechanism_drivers'] {
  $mechanism_drivers = split($neutron_settings['L2']['mechanism_drivers'], ',')
} else {
  $mechanism_drivers = ['openvswitch', 'l2population']
}

# by default we use ML2 plugin
$core_plugin      = 'neutron.plugins.ml2.plugin.Ml2Plugin'
$agent            = 'ml2-ovs'

$dvr           = pick($neutron_advanced_config['neutron_dvr'], false)
$l2_population = pick($neutron_advanced_config['neutron_l2_pop'], false)

if $dvr {
  $agents = [$agent, 'l3' , 'metadata']
}
else {
  $agents = [$agent]
}

exec { 'wait-for-int-br':
  command   => "ovs-vsctl br-exists $neutron_integration_bridge",
  path      => [ '/sbin', '/bin', '/usr/bin', '/usr/sbin' ],
  try_sleep => 5,
  tries     => 10,
}

Class['Openstack::Network'] -> Exec['wait-for-int-br'] -> Service['nova-compute']

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
