anchor { 'l23network::init':
  before => ['K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]', 'K_mod[openvswitch]', 'K_mod[8021q]', 'K_mod[bonding]', 'K_mod[bridge]'],
  name   => 'l23network::init',
}

anchor { 'l23network::l2::init':
  before => ['File[/etc/network/interfaces.d]', 'File[/etc/network/interfaces]', 'Anchor[l23network::init]'],
  name   => 'l23network::l2::init',
}

class { 'L23network::L2':
  ensure_package               => 'present',
  install_bondtool             => 'true',
  install_brtool               => 'true',
  install_ethtool              => 'true',
  install_ovs                  => 'false',
  install_vlantool             => 'true',
  name                         => 'L23network::L2',
  ovs_common_package_name      => 'openvswitch-switch',
  ovs_datapath_package_name    => 'openvswitch-datapath-dkms',
  ovs_module_name              => 'openvswitch',
  use_lnx                      => 'true',
  use_ovs                      => 'false',
  use_ovs_dkms_datapath_module => 'true',
}

class { 'L23network::Params':
  name => 'L23network::Params',
}

class { 'L23network':
  before                       => 'Exec[wait-for-interfaces]',
  disable_hotplug              => 'true',
  ensure_package               => 'present',
  install_ovs                  => 'false',
  name                         => 'L23network',
  use_lnx                      => 'true',
  use_ovs                      => 'false',
  use_ovs_dkms_datapath_module => 'true',
}

class { 'Openstack::Keepalive':
  name         => 'Openstack::Keepalive',
  tcp_retries2 => '5',
  tcpka_intvl  => '3',
  tcpka_probes => '8',
  tcpka_time   => '30',
}

class { 'Openstack::Reserved_ports':
  name  => 'Openstack::Reserved_ports',
  ports => '49000,49001,35357,41055,41056,55572,58882',
}

class { 'Settings':
  name => 'Settings',
}

class { 'Stdlib::Stages':
  name => 'Stdlib::Stages',
}

class { 'Stdlib':
  name => 'Stdlib',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'Sysfs::Install':
  before => ['Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]'],
  name   => 'Sysfs::Install',
  notify => 'Class[Sysfs::Service]',
}

class { 'Sysfs::Params':
  name => 'Sysfs::Params',
}

class { 'Sysfs::Service':
  name => 'Sysfs::Service',
}

class { 'Sysfs':
  name => 'Sysfs',
}

class { 'main':
  name => 'main',
}

disable_hotplug { 'global':
  ensure => 'present',
  before => ['Anchor[l23network::init]', 'Enable_hotplug[global]'],
  name   => 'global',
}

enable_hotplug { 'global':
  ensure => 'present',
  name   => 'global',
}

exec { 'remove_sysfsutils_override':
  before  => 'Service[sysfsutils]',
  command => 'rm -f /etc/init/sysfsutils.override',
  onlyif  => 'test -f /etc/init/sysfsutils.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

exec { 'wait-for-interfaces':
  command => 'sleep 32',
  path    => '/usr/bin:/bin',
}

file { '/etc/network/interfaces.d':
  ensure => 'directory',
  before => 'Anchor[l23network::init]',
  mode   => '0755',
  owner  => 'root',
  path   => '/etc/network/interfaces.d',
}

file { '/etc/network/interfaces':
  ensure  => 'present',
  before  => 'File[/etc/network/interfaces.d]',
  content => 'source /etc/network/interfaces.d/*
',
  path    => '/etc/network/interfaces',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

file { 'create_sysfsutils_override':
  ensure  => 'present',
  before  => ['Package[sysfsutils]', 'Package[sysfsutils]', 'Exec[remove_sysfsutils_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/sysfsutils.override',
}

file { 'sysfs.d':
  ensure => 'directory',
  group  => 'root',
  mode   => '0755',
  owner  => 'root',
  path   => '/etc/sysfs.d',
}

k_mod { '8021q':
  ensure => 'present',
  before => ['L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]'],
  module => '8021q',
}

k_mod { 'bonding':
  ensure => 'present',
  before => ['L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]'],
  module => 'bonding',
}

k_mod { 'bridge':
  ensure => 'present',
  before => ['L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]'],
  module => 'bridge',
}

k_mod { 'openvswitch':
  ensure => 'absent',
  before => ['L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_bridge[br-fw-admin]', 'L2_bridge[br-storage]', 'L2_bridge[br-mgmt]', 'L2_bridge[br-ex]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]', 'L2_port[eth0]', 'L2_port[eth0.102]', 'L2_port[eth0.101]', 'L2_port[eth1]', 'L2_port[eth0.103]'],
  module => 'openvswitch',
}

l23_stored_config { 'br-ex':
  ensure       => 'present',
  before       => ['Enable_hotplug[global]', 'L2_bridge[br-ex]', 'L3_ifconfig[br-ex]'],
  bridge_ports => 'none',
  gateway      => '172.16.0.1',
  if_type      => 'bridge',
  ipaddr       => '172.16.0.4/24',
  method       => 'static',
  name         => 'br-ex',
  provider     => 'lnx_ubuntu',
}

l23_stored_config { 'br-fw-admin':
  ensure       => 'present',
  before       => ['Enable_hotplug[global]', 'L2_bridge[br-fw-admin]', 'L3_ifconfig[br-fw-admin]'],
  bridge_ports => 'none',
  if_type      => 'bridge',
  ipaddr       => '10.108.0.7/24',
  method       => 'static',
  name         => 'br-fw-admin',
  provider     => 'lnx_ubuntu',
}

l23_stored_config { 'br-mgmt':
  ensure       => 'present',
  before       => ['Enable_hotplug[global]', 'L2_bridge[br-mgmt]', 'L3_ifconfig[br-mgmt]'],
  bridge_ports => 'none',
  if_type      => 'bridge',
  ipaddr       => '192.168.0.3/24',
  method       => 'static',
  name         => 'br-mgmt',
  provider     => 'lnx_ubuntu',
}

l23_stored_config { 'br-storage':
  ensure       => 'present',
  before       => ['Enable_hotplug[global]', 'L2_bridge[br-storage]', 'L3_ifconfig[br-storage]'],
  bridge_ports => 'none',
  if_type      => 'bridge',
  ipaddr       => '192.168.1.3/24',
  method       => 'static',
  name         => 'br-storage',
  provider     => 'lnx_ubuntu',
}

l23_stored_config { 'eth0.101':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'L2_port[eth0.101]'],
  bridge    => 'br-mgmt',
  name      => 'eth0.101',
  provider  => 'lnx_ubuntu',
  vlan_dev  => 'eth0',
  vlan_id   => '101',
  vlan_mode => 'eth',
}

l23_stored_config { 'eth0.102':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'L2_port[eth0.102]'],
  bridge    => 'br-storage',
  name      => 'eth0.102',
  provider  => 'lnx_ubuntu',
  vlan_dev  => 'eth0',
  vlan_id   => '102',
  vlan_mode => 'eth',
}

l23_stored_config { 'eth0.103':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'L2_port[eth0.103]', 'L3_ifconfig[eth0.103]'],
  ipaddr    => 'none',
  method    => 'manual',
  name      => 'eth0.103',
  provider  => 'lnx_ubuntu',
  vlan_dev  => 'eth0',
  vlan_id   => '103',
  vlan_mode => 'eth',
}

l23_stored_config { 'eth0':
  ensure   => 'present',
  before   => ['Enable_hotplug[global]', 'L2_port[eth0]'],
  bridge   => 'br-fw-admin',
  name     => 'eth0',
  provider => 'lnx_ubuntu',
}

l23_stored_config { 'eth1':
  ensure   => 'present',
  before   => ['Enable_hotplug[global]', 'L2_port[eth1]'],
  bridge   => 'br-ex',
  name     => 'eth1',
  provider => 'lnx_ubuntu',
}

l23network::l2::bridge { 'br-ex':
  ensure       => 'present',
  before       => 'L3_ifconfig[br-ex]',
  bpdu_forward => 'true',
  external_ids => {'bridge-id' => 'br-ex'},
  name         => 'br-ex',
  provider     => 'lnx',
  require      => 'L23network::L3::Ifconfig[br-mgmt]',
  use_ovs      => 'false',
}

l23network::l2::bridge { 'br-fw-admin':
  ensure       => 'present',
  before       => 'L3_ifconfig[br-fw-admin]',
  bpdu_forward => 'true',
  external_ids => {'bridge-id' => 'br-fw-admin'},
  name         => 'br-fw-admin',
  provider     => 'lnx',
  use_ovs      => 'false',
}

l23network::l2::bridge { 'br-mgmt':
  ensure       => 'present',
  before       => 'L3_ifconfig[br-mgmt]',
  bpdu_forward => 'true',
  external_ids => {'bridge-id' => 'br-mgmt'},
  name         => 'br-mgmt',
  provider     => 'lnx',
  require      => 'L23network::L3::Ifconfig[br-storage]',
  use_ovs      => 'false',
}

l23network::l2::bridge { 'br-storage':
  ensure       => 'present',
  before       => 'L3_ifconfig[br-storage]',
  bpdu_forward => 'true',
  external_ids => {'bridge-id' => 'br-storage'},
  name         => 'br-storage',
  provider     => 'lnx',
  require      => 'L23network::L3::Ifconfig[br-fw-admin]',
  use_ovs      => 'false',
}

l23network::l2::port { 'eth0.101':
  ensure   => 'present',
  bridge   => 'br-mgmt',
  name     => 'eth0.101',
  port     => 'eth0.101',
  provider => 'lnx',
  require  => 'L23network::L2::Port[eth0.102]',
  use_ovs  => 'false',
}

l23network::l2::port { 'eth0.102':
  ensure   => 'present',
  bridge   => 'br-storage',
  name     => 'eth0.102',
  port     => 'eth0.102',
  provider => 'lnx',
  require  => 'L23network::L2::Port[eth0]',
  use_ovs  => 'false',
}

l23network::l2::port { 'eth0.103':
  ensure   => 'present',
  before   => 'L3_ifconfig[eth0.103]',
  name     => 'eth0.103',
  port     => 'eth0.103',
  provider => 'lnx',
  require  => 'L23network::L2::Port[eth1]',
  use_ovs  => 'false',
}

l23network::l2::port { 'eth0':
  ensure   => 'present',
  bridge   => 'br-fw-admin',
  name     => 'eth0',
  port     => 'eth0',
  provider => 'lnx',
  require  => 'L23network::L3::Ifconfig[br-ex]',
  use_ovs  => 'false',
}

l23network::l2::port { 'eth1':
  ensure   => 'present',
  bridge   => 'br-ex',
  name     => 'eth1',
  port     => 'eth1',
  provider => 'lnx',
  require  => 'L23network::L2::Port[eth0.101]',
  use_ovs  => 'false',
}

l23network::l3::ifconfig { 'br-ex':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  gateway               => '172.16.0.1',
  interface             => 'br-ex',
  ipaddr                => '172.16.0.4/24',
  name                  => 'br-ex',
  require               => 'L3_clear_route[default]',
}

l23network::l3::ifconfig { 'br-fw-admin':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  interface             => 'br-fw-admin',
  ipaddr                => '10.108.0.7/24',
  name                  => 'br-fw-admin',
  require               => 'L23network::L2::Bridge[br-fw-admin]',
}

l23network::l3::ifconfig { 'br-mgmt':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  interface             => 'br-mgmt',
  ipaddr                => '192.168.0.3/24',
  name                  => 'br-mgmt',
  require               => 'L23network::L2::Bridge[br-mgmt]',
}

l23network::l3::ifconfig { 'br-storage':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  interface             => 'br-storage',
  ipaddr                => '192.168.1.3/24',
  name                  => 'br-storage',
  require               => 'L23network::L2::Bridge[br-storage]',
}

l23network::l3::ifconfig { 'eth0.103':
  ensure                => 'present',
  check_by_ping         => 'gateway',
  check_by_ping_timeout => '30',
  interface             => 'eth0.103',
  ipaddr                => 'none',
  name                  => 'eth0.103',
  require               => 'L23network::L2::Port[eth0.103]',
}

l2_bridge { 'br-ex':
  ensure       => 'present',
  before       => 'Enable_hotplug[global]',
  bridge       => 'br-ex',
  external_ids => {'bridge-id' => 'br-ex'},
  provider     => 'lnx',
  use_ovs      => 'false',
}

l2_bridge { 'br-fw-admin':
  ensure       => 'present',
  before       => 'Enable_hotplug[global]',
  bridge       => 'br-fw-admin',
  external_ids => {'bridge-id' => 'br-fw-admin'},
  provider     => 'lnx',
  use_ovs      => 'false',
}

l2_bridge { 'br-mgmt':
  ensure       => 'present',
  before       => 'Enable_hotplug[global]',
  bridge       => 'br-mgmt',
  external_ids => {'bridge-id' => 'br-mgmt'},
  provider     => 'lnx',
  use_ovs      => 'false',
}

l2_bridge { 'br-storage':
  ensure       => 'present',
  before       => 'Enable_hotplug[global]',
  bridge       => 'br-storage',
  external_ids => {'bridge-id' => 'br-storage'},
  provider     => 'lnx',
  use_ovs      => 'false',
}

l2_port { 'eth0.101':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  bridge    => 'br-mgmt',
  interface => 'eth0.101',
  provider  => 'lnx',
  use_ovs   => 'false',
  vlan_dev  => 'eth0',
  vlan_id   => '101',
  vlan_mode => 'eth',
}

l2_port { 'eth0.102':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  bridge    => 'br-storage',
  interface => 'eth0.102',
  provider  => 'lnx',
  use_ovs   => 'false',
  vlan_dev  => 'eth0',
  vlan_id   => '102',
  vlan_mode => 'eth',
}

l2_port { 'eth0.103':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  interface => 'eth0.103',
  provider  => 'lnx',
  use_ovs   => 'false',
  vlan_dev  => 'eth0',
  vlan_id   => '103',
  vlan_mode => 'eth',
}

l2_port { 'eth0':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  bridge    => 'br-fw-admin',
  interface => 'eth0',
  provider  => 'lnx',
  use_ovs   => 'false',
}

l2_port { 'eth1':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  bridge    => 'br-ex',
  interface => 'eth1',
  provider  => 'lnx',
  use_ovs   => 'false',
}

l3_clear_route { 'default':
  ensure      => 'absent',
  destination => 'default',
  gateway     => '172.16.0.1',
  interface   => 'br-ex',
  name        => 'default',
  require     => 'L23network::L2::Bridge[br-ex]',
}

l3_ifconfig { 'br-ex':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  gateway   => '172.16.0.1',
  interface => 'br-ex',
  ipaddr    => '172.16.0.4/24',
}

l3_ifconfig { 'br-fw-admin':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  interface => 'br-fw-admin',
  ipaddr    => '10.108.0.7/24',
}

l3_ifconfig { 'br-mgmt':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  interface => 'br-mgmt',
  ipaddr    => '192.168.0.3/24',
}

l3_ifconfig { 'br-storage':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  interface => 'br-storage',
  ipaddr    => '192.168.1.3/24',
}

l3_ifconfig { 'eth0.103':
  ensure    => 'present',
  before    => ['Enable_hotplug[global]', 'Sysfs_config_value[rps_cpus]', 'Sysfs_config_value[xps_cpus]', 'Ping_host[172.16.0.1]'],
  interface => 'eth0.103',
  ipaddr    => 'none',
}

notify { 'SDN':
  message => 'add-br(br-fw-admin) -> endpoint(br-fw-admin) -> add-br(br-storage) -> endpoint(br-storage) -> add-br(br-mgmt) -> endpoint(br-mgmt) -> add-br(br-ex) -> endpoint(br-ex) -> add-port(eth0) -> add-port(eth0.102) -> add-port(eth0.101) -> add-port(eth1) -> add-port(eth0.103) -> endpoint(eth0.103)',
  name    => 'SDN',
}

package { 'bridge-utils':
  ensure => 'present',
  name   => 'bridge-utils',
}

package { 'ethtool':
  ensure => 'present',
  before => 'Anchor[l23network::l2::init]',
  name   => 'ethtool',
}

package { 'ifenslave':
  ensure => 'present',
  before => 'Anchor[l23network::l2::init]',
  name   => 'ifenslave',
}

package { 'iputils-arping':
  ensure => 'present',
  name   => 'iputils-arping',
}

package { 'irqbalance':
  ensure => 'installed',
  name   => 'irqbalance',
}

package { 'sysfsutils':
  ensure => 'installed',
  before => ['Exec[remove_sysfsutils_override]', 'Exec[remove_sysfsutils_override]'],
  name   => 'sysfsutils',
}

package { 'vlan':
  ensure => 'present',
  before => 'Anchor[l23network::l2::init]',
  name   => 'vlan',
}

ping_host { '172.16.0.1':
  ensure => 'up',
  name   => '172.16.0.1',
}

service { 'irqbalance':
  ensure  => 'running',
  name    => 'irqbalance',
  require => 'Package[irqbalance]',
}

service { 'sysfsutils':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'false',
  name       => 'sysfsutils',
}

stage { 'deploy':
  name => 'deploy',
}

stage { 'deploy_app':
  before => 'Stage[deploy]',
  name   => 'deploy_app',
}

stage { 'deploy_infra':
  before => 'Stage[setup_app]',
  name   => 'deploy_infra',
}

stage { 'main':
  name => 'main',
}

stage { 'runtime':
  before  => 'Stage[setup_infra]',
  name    => 'runtime',
  require => 'Stage[main]',
}

stage { 'setup':
  before => 'Stage[main]',
  name   => 'setup',
}

stage { 'setup_app':
  before => 'Stage[deploy_app]',
  name   => 'setup_app',
}

stage { 'setup_infra':
  before => 'Stage[deploy_infra]',
  name   => 'setup_infra',
}

sysctl::value { 'net.core.netdev_max_backlog':
  key     => 'net.core.netdev_max_backlog',
  name    => 'net.core.netdev_max_backlog',
  require => 'Class[Sysctl::Base]',
  value   => '261144',
}

sysctl::value { 'net.ipv4.conf.all.arp_accept':
  key     => 'net.ipv4.conf.all.arp_accept',
  name    => 'net.ipv4.conf.all.arp_accept',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl::value { 'net.ipv4.conf.default.arp_accept':
  key     => 'net.ipv4.conf.default.arp_accept',
  name    => 'net.ipv4.conf.default.arp_accept',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl::value { 'net.ipv4.ip_local_reserved_ports':
  key     => 'net.ipv4.ip_local_reserved_ports',
  name    => 'net.ipv4.ip_local_reserved_ports',
  require => 'Class[Sysctl::Base]',
  value   => '49000,49001,35357,41055,41056,55572,58882',
}

sysctl::value { 'net.ipv4.tcp_keepalive_intvl':
  key     => 'net.ipv4.tcp_keepalive_intvl',
  name    => 'net.ipv4.tcp_keepalive_intvl',
  require => 'Class[Sysctl::Base]',
  value   => '3',
}

sysctl::value { 'net.ipv4.tcp_keepalive_probes':
  key     => 'net.ipv4.tcp_keepalive_probes',
  name    => 'net.ipv4.tcp_keepalive_probes',
  require => 'Class[Sysctl::Base]',
  value   => '8',
}

sysctl::value { 'net.ipv4.tcp_keepalive_time':
  key     => 'net.ipv4.tcp_keepalive_time',
  name    => 'net.ipv4.tcp_keepalive_time',
  require => 'Class[Sysctl::Base]',
  value   => '30',
}

sysctl::value { 'net.ipv4.tcp_retries2':
  key     => 'net.ipv4.tcp_retries2',
  name    => 'net.ipv4.tcp_retries2',
  require => 'Class[Sysctl::Base]',
  value   => '5',
}

sysctl { 'net.core.netdev_max_backlog':
  before => 'Sysctl_runtime[net.core.netdev_max_backlog]',
  name   => 'net.core.netdev_max_backlog',
  val    => '261144',
}

sysctl { 'net.ipv4.conf.all.arp_accept':
  before => 'Sysctl_runtime[net.ipv4.conf.all.arp_accept]',
  name   => 'net.ipv4.conf.all.arp_accept',
  val    => '1',
}

sysctl { 'net.ipv4.conf.default.arp_accept':
  before => 'Sysctl_runtime[net.ipv4.conf.default.arp_accept]',
  name   => 'net.ipv4.conf.default.arp_accept',
  val    => '1',
}

sysctl { 'net.ipv4.ip_local_reserved_ports':
  before => 'Sysctl_runtime[net.ipv4.ip_local_reserved_ports]',
  name   => 'net.ipv4.ip_local_reserved_ports',
  val    => '49000,49001,35357,41055,41056,55572,58882',
}

sysctl { 'net.ipv4.tcp_keepalive_intvl':
  before => 'Sysctl_runtime[net.ipv4.tcp_keepalive_intvl]',
  name   => 'net.ipv4.tcp_keepalive_intvl',
  val    => '3',
}

sysctl { 'net.ipv4.tcp_keepalive_probes':
  before => 'Sysctl_runtime[net.ipv4.tcp_keepalive_probes]',
  name   => 'net.ipv4.tcp_keepalive_probes',
  val    => '8',
}

sysctl { 'net.ipv4.tcp_keepalive_time':
  before => 'Sysctl_runtime[net.ipv4.tcp_keepalive_time]',
  name   => 'net.ipv4.tcp_keepalive_time',
  val    => '30',
}

sysctl { 'net.ipv4.tcp_retries2':
  before => 'Sysctl_runtime[net.ipv4.tcp_retries2]',
  name   => 'net.ipv4.tcp_retries2',
  val    => '5',
}

sysctl_runtime { 'net.core.netdev_max_backlog':
  name => 'net.core.netdev_max_backlog',
  val  => '261144',
}

sysctl_runtime { 'net.ipv4.conf.all.arp_accept':
  name => 'net.ipv4.conf.all.arp_accept',
  val  => '1',
}

sysctl_runtime { 'net.ipv4.conf.default.arp_accept':
  name => 'net.ipv4.conf.default.arp_accept',
  val  => '1',
}

sysctl_runtime { 'net.ipv4.ip_local_reserved_ports':
  name => 'net.ipv4.ip_local_reserved_ports',
  val  => '49000,49001,35357,41055,41056,55572,58882',
}

sysctl_runtime { 'net.ipv4.tcp_keepalive_intvl':
  name => 'net.ipv4.tcp_keepalive_intvl',
  val  => '3',
}

sysctl_runtime { 'net.ipv4.tcp_keepalive_probes':
  name => 'net.ipv4.tcp_keepalive_probes',
  val  => '8',
}

sysctl_runtime { 'net.ipv4.tcp_keepalive_time':
  name => 'net.ipv4.tcp_keepalive_time',
  val  => '30',
}

sysctl_runtime { 'net.ipv4.tcp_retries2':
  name => 'net.ipv4.tcp_retries2',
  val  => '5',
}

sysfs_config_value { 'rps_cpus':
  ensure  => 'present',
  exclude => '/sys/class/net/lo/*',
  name    => '/etc/sysfs.d/rps_cpus.conf',
  notify  => 'Service[sysfsutils]',
  sysfs   => '/sys/class/net/*/queues/rx-*/rps_cpus',
  value   => 'f',
}

sysfs_config_value { 'xps_cpus':
  ensure  => 'present',
  exclude => '/sys/class/net/lo/*',
  name    => '/etc/sysfs.d/xps_cpus.conf',
  notify  => 'Service[sysfsutils]',
  sysfs   => '/sys/class/net/*/queues/tx-*/xps_cpus',
  value   => 'f',
}

tweaks::ubuntu_service_override { 'sysfsutils':
  name         => 'sysfsutils',
  package_name => 'sysfsutils',
  service_name => 'sysfsutils',
}

