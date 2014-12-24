import '../globals.pp'

if $role == 'primary-controller' {
  $primary_controller = true
} else {
   $primary_controller = false
}

$primary_controller_nodes    = filter_nodes($nodes_hash,'role','primary-controller')
$vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
$vip_public_cidr_netmask     = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])

if $use_neutron {
  $vip_mgmt_other_nets = join($network_scheme['endpoints'][$internal_int]['other_nets'], ' ')
}

# Do not convert to ARRAY, It can't work in 2.7
$vips = {
  'management'   => {
    namespace            => 'haproxy',
    nic                  => $internal_int,
    base_veth            => "${internal_int}-hapr",
    ns_veth              => "hapr-m",
    ip                   => hiera('management_vip'),
    cidr_netmask         => $vip_management_cidr_netmask,
    gateway              => 'link',
    gateway_metric       => '20',
    other_networks       => $vip_mgmt_other_nets,
    iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -I POSTROUTING -m mark --mark 0x2b ! -o ${internal_int} -j MASQUERADE",
    iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -D POSTROUTING -m mark --mark 0x2b ! -o ${internal_int} -j MASQUERADE",
    iptables_comment     => "masquerade-for-management-net",
    tie_with_ping        => false,
    ping_host_list       => "",
  },
}

if $public_int {
  if $use_neutron {
    $vip_publ_other_nets = join($network_scheme['endpoints'][$public_int]['other_nets'], ' ')
    $ping_host_list = $network_scheme['endpoints']['br-ex']['gateway']
  } else {
    $network_data = hiera('network_data')
    $ping_host_list = $network_data[$public_int]['gateway']
  }

  $run_ping_checker = hiera('run_ping_checker', true)

  $vips['public'] = {
    namespace            => 'haproxy',
    nic                  => $public_int,
    base_veth            => "${public_int}-hapr",
    ns_veth              => "hapr-p",
    ip                   => hiera('public_vip'),
    cidr_netmask         => $vip_public_cidr_netmask,
    gateway              => 'link',
    gateway_metric       => '10',
    other_networks       => $vip_publ_other_nets,
    iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -I POSTROUTING -m mark --mark 0x2a ! -o ${public_int} -j MASQUERADE",
    iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -D POSTROUTING -m mark --mark 0x2a ! -o ${public_int} -j MASQUERADE",
    iptables_comment     => "masquerade-for-public-net",
    tie_with_ping        => $run_ping_checker,
    ping_host_list       => $ping_host_list,
  }
}

$vip_keys = keys($vips)

##REFACTORING NEEDED


##TODO: simply parse nodes array
$controllers = concat($primary_controller_nodes, filter_nodes($nodes_hash, 'role', 'controller'))
$controller_internal_addresses = nodes_to_hash($controllers, 'name', 'internal_address')
$controller_public_addresses = nodes_to_hash($controllers, 'name', 'public_address')
$controller_storage_addresses = nodes_to_hash($controllers, 'name', 'storage_address')
$controller_hostnames = keys($controller_internal_addresses)
$controller_nodes = ipsort(values($controller_internal_addresses))
$controller_node_public  = hiera('public_vip')
$controller_node_address = hiera('management_vip')

$roles = node_roles($nodes_hash, hiera('uid'))
$mountpoints = filter_hash($mp_hash, 'point')

# AMQP client configuration
if $internal_address in $controller_nodes {
# prefer local MQ broker if it exists on this node
  $amqp_nodes = concat(['127.0.0.1'], fqdn_rotate(delete($controller_nodes, $internal_address)))
} else {
  $amqp_nodes = fqdn_rotate($controller_nodes)
}

$amqp_port = '5673'
$amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.join ',' %>")
$rabbit_ha_queues = true

# RabbitMQ server configuration
$rabbitmq_bind_ip_address = 'UNSET'              # bind RabbitMQ to 0.0.0.0
$rabbitmq_bind_port = $amqp_port
$rabbitmq_cluster_nodes = $controller_hostnames  # has to be hostnames

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
  $use_swift = true
} else {
  $use_swift = false
}

if ($use_swift) {
  if ! hiera('swift_partition') {
    $swift_partition = '/var/lib/glance/node'
  }
  $swift_proxies            = $controllers
  $swift_local_net_ip       = $storage_address
  $master_swift_proxy_nodes = filter_nodes($nodes_hash, 'role', 'primary-controller')
  $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']

  $swift_loopback = false
  if $primary_controller {
    $primary_proxy = true
  } else {
    $primary_proxy = false
  }
} elsif ($storage_hash['objects_ceph']) {
  $rgw_servers = $controllers
}

$multi_host  = true
$mirror_type = 'external'

if $use_neutron {
  $private_interface = false
  $floating_range = {}
  $fixed_range = false
} else {
  $private_interface = hiera('fixed_interface')
  $floating_range = false
  $fixed_range = hiera('fixed_network_range')
}

############################################################################################

class { 'cluster':
  internal_address  => $internal_address,
  unicast_addresses => $osnailyfacter::cluster_ha::controller_internal_addresses,
}

cluster::virtual_ips { $vip_keys:
  vips => $vips,
}

Class['cluster'] -> Cluster::Virtual_ips[$vip_keys]

class { 'cluster::haproxy':
  haproxy_maxconn    => '16000',
  haproxy_bufsize    => '32768',
  primary_controller => $primary_controller
}

# Some topologies might need to keep the vips on the same node during
# deploymenet. This wouldls only need to be changed by hand.
$keep_vips_together = false
if ($keep_vips_together) {
  cs_colocation { 'ha_vips':
    ensure      => 'present',
    primitives  => [ prefix(keys($vips),"vip__") ],
  }
  Cluster::Virtual_ips[$vip_keys] -> Cs_colocation['ha_vips']
}

class { 'openstack::controller_ha':
  controllers                    => $controllers,
  controller_public_addresses    => $controller_public_addresses,
  controller_internal_addresses  => $controller_internal_addresses,
  internal_address               => $internal_address,
  public_interface               => $public_int,
  private_interface              => $private_interface,
  internal_virtual_ip            => hiera('management_vip'),
  public_virtual_ip              => hiera('public_vip'),
  primary_controller             => $primary_controller,
  floating_range                 => $floating_range,
  fixed_range                    => $fixed_range,
  multi_host                     => $multi_host,
  network_manager                => $network_manager,
  num_networks                   => $num_networks,
  network_size                   => $network_size,
  network_config                 => $network_config,
  debug                          => $debug,
  verbose                        => $verbose,
  auto_assign_floating_ip        => hiera('auto_assign_floating_ip'),
  mysql_root_password            => $mysql_hash['root_password'],
  admin_email                    => $access_hash['email'],
  admin_user                     => $access_hash['user'],
  admin_password                 => $access_hash['password'],
  keystone_db_password           => $keystone_hash['db_password'],
  keystone_admin_token           => $keystone_hash['admin_token'],
  keystone_admin_tenant          => $access_hash['tenant'],
  glance_db_password             => $glance_hash['db_password'],
  glance_user_password           => $glance_hash['user_password'],
  glance_image_cache_max_size    => $glance_hash['image_cache_max_size'],
  known_stores                   => $glance_known_stores,
  glance_vcenter_host            => $storage_hash['vc_host'],
  glance_vcenter_user            => $storage_hash['vc_user'],
  glance_vcenter_password        => $storage_hash['vc_password'],
  glance_vcenter_datacenter      => $storage_hash['vc_datacenter'],
  glance_vcenter_datastore       => $storage_hash['vc_datastore'],
  glance_vcenter_image_dir       => $storage_hash['vc_image_dir'],
  nova_db_password               => $nova_hash['db_password'],
  nova_user_password             => $nova_hash['user_password'],
  queue_provider                 => $queue_provider,
  amqp_hosts                     => $amqp_hosts,
  amqp_user                      => $rabbit_hash['user'],
  amqp_password                  => $rabbit_hash['password'],
  rabbit_ha_queues               => $rabbit_ha_queues,
  rabbitmq_bind_ip_address       => $rabbitmq_bind_ip_address,
  rabbitmq_bind_port             => $rabbitmq_bind_port,
  rabbitmq_cluster_nodes         => $rabbitmq_cluster_nodes,
  memcached_servers              => $controller_nodes,
  memcached_bind_address         => $internal_address,
  export_resources               => false,
  glance_backend                 => $glance_backend,
  swift_proxies                  => $swift_proxies,
  rgw_servers                    => $rgw_servers,

  network_provider               => $network_provider,
  neutron_db_password            => $neutron_db_password,
  neutron_user_password          => $neutron_user_password,
  neutron_metadata_proxy_secret  => $neutron_metadata_proxy_secret,
  neutron_ha_agents              => $primary_controller ? {true => 'primary', default => 'slave'},
  base_mac                       => $base_mac,

  cinder                         => true,
  cinder_user_password           => $cinder_hash['user_password'],
  cinder_iscsi_bind_addr         => $cinder_iscsi_bind_addr,
  cinder_db_password             => $cinder_hash['db_password'],
  cinder_volume_group            => 'cinder',
  manage_volumes                 => $manage_volumes,
  ceilometer                     => $ceilometer_hash['enabled'],
  ceilometer_db_password         => $ceilometer_hash['db_password'],
  ceilometer_user_password       => $ceilometer_hash['user_password'],
  ceilometer_metering_secret     => $ceilometer_hash['metering_secret'],
  ceilometer_db_type             => 'mongodb',
  ceilometer_db_host             => mongo_hosts($nodes_hash),
  swift_rados_backend            => $storage_hash['objects_ceph'],
  galera_nodes                   => $controller_nodes,
  novnc_address                  => $internal_address,
  sahara                         => $sahara_hash['enabled'],
  murano                         => $murano_hash['enabled'],
  custom_mysql_setup_class       => $custom_mysql_setup_class,
  mysql_skip_name_resolve        => true,
  use_syslog                     => $use_syslog,
  syslog_log_facility_glance     => $syslog_log_facility_glance,
  syslog_log_facility_cinder     => $syslog_log_facility_cinder,
  syslog_log_facility_neutron    => $syslog_log_facility_neutron,
  syslog_log_facility_nova       => $syslog_log_facility_nova,
  syslog_log_facility_keystone   => $syslog_log_facility_keystone,
  syslog_log_facility_ceilometer => $syslog_log_facility_ceilometer,
  nova_rate_limits               => $nova_rate_limits,
  cinder_rate_limits             => $cinder_rate_limits,
  horizon_use_ssl                => hiera('horizon_use_ssl'),
  use_unicast_corosync           => hiera('use_unicast_corosync'),
  nameservers                    => $dns_nameservers,
  max_retries                    => $max_retries,
  max_pool_size                  => $max_pool_size,
  max_overflow                   => $max_overflow,
  idle_timeout                   => $idle_timeout,
  nova_report_interval           => $nova_report_interval,
  nova_service_down_time         => $nova_service_down_time,
}


# TODO: move to separate file
if ($use_swift) {
  $swift_zone = $node[0]['swift_zone']

# At least debian glance-common package chowns whole /var/lib/glance recursively
# which breaks swift ownership of dirs inside $storage_mnt_base_dir (default: /var/lib/glance/node/)
# so we just need to make sure package glance-common (dependency for glance-api) is already installed
# before creating swift device directories

  Package[$glance::params::api_package_name] -> Anchor <| title=='swift-device-directories-start' |>

  class { 'openstack::swift::storage_node':
    storage_type          => $swift_loopback,
    loopback_size         => '5243780',
    storage_mnt_base_dir  => $swift_partition,
    storage_devices       => $mountpoints,
    swift_zone            => $swift_zone,
    swift_local_net_ip    => $storage_address,
    master_swift_proxy_ip => $master_swift_proxy_ip,
    sync_rings            => ! $primary_proxy,
    debug                 => $debug,
    verbose               => $verbose,
    log_facility          => 'LOG_SYSLOG',
  }
  if $primary_proxy {
    ring_devices {'all':
      storages => $controllers,
      require  => Class['swift'],
    }
  }

  if !$swift_hash['resize_value']
  {
    $swift_hash['resize_value'] = 2
  }

  $ring_part_power = calc_ring_part_power($controllers, $swift_hash['resize_value'])

  class { 'openstack::swift::proxy':
    swift_user_password     => $swift_hash['user_password'],
    swift_proxies           => $controller_internal_addresses,
    ring_part_power         => $ring_part_power,
    primary_proxy           => $primary_proxy,
    controller_node_address => hiera('management_vip'),
    swift_local_net_ip      => $swift_local_net_ip,
    master_swift_proxy_ip   => $master_swift_proxy_ip,
    debug                   => $debug,
    verbose                 => $verbose,
    log_facility            => 'LOG_SYSLOG',
  }

  class { 'swift::keystone::auth':
    password         => $swift_hash['user_password'],
    public_address   => hiera('public_vip'),
    internal_address => hiera('management_vip'),
    admin_address    => hiera('management_vip'),
  }

}
# end swift

nova_config { 'DEFAULT/resume_guests_state_on_host_boot': value => hiera('resume_guests_state_on_host_boot') }
nova_config { 'DEFAULT/use_cow_images':                   value => hiera('use_cow_images') }
nova_config { 'DEFAULT/compute_scheduler_driver':         value => hiera('compute_scheduler_driver') }
nova_config { 'DEFAULT/ram_weight_multiplier':            value => '1.0' }

# TODO(bogdando) move exec checkers to puppet native types for haproxy backends
if $primary_controller {
  exec { 'wait-for-haproxy-keystone-backend':
    command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep '^keystone-1,' | egrep -v ',FRONTEND,|,BACKEND,' | grep -qv ',INI,' &&
                        echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^keystone-1,BACKEND,.*,UP,'",
    path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    try_sleep => 5,
    tries     => 60,
    require   => Package['socat'],
  }
  exec { 'wait-for-haproxy-keystone-admin-backend':
    command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep '^keystone-2,' | egrep -v ',FRONTEND,|,BACKEND,' | grep -qv ',INI,' &&
                        echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^keystone-2,BACKEND,.*,UP,'",
    path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    try_sleep => 5,
    tries     => 60,
    require   => Package['socat'],
  }

  Openstack::Ha::Haproxy_service <| |> -> Exec<| title=='wait-for-haproxy-keystone-admin-backend' |>
  Openstack::Ha::Haproxy_service <| |> -> Exec<| title=='wait-for-haproxy-keystone-backend' |>

  Class['keystone', 'openstack::ha::keystone'] -> Exec<| title=='wait-for-haproxy-keystone-backend' |>
  Class['keystone', 'openstack::ha::keystone'] -> Exec<| title=='wait-for-haproxy-keystone-admin-backend' |>

  exec { 'wait-for-haproxy-nova-backend':
    command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep '^nova-api-2,' | egrep -v ',FRONTEND,|,BACKEND,' | grep -qv ',INI,' &&
                        echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^nova-api-2,BACKEND,.*,UP,'",
    path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    try_sleep => 5,
    tries     => 60,
    require   => Package['socat'],
  }

  Openstack::Ha::Haproxy_service <| |> -> Exec<| title=='wait-for-haproxy-nova-backend' |>
  Class['nova::api', 'openstack::ha::nova', 'nova::keystone::auth'] -> Exec<| title=='wait-for-haproxy-nova-backend' |>

  exec {'create-m1.micro-flavor':
    command => "bash -c \"source /root/openrc; nova flavor-create --is-public true m1.micro auto 64 0 1\"",
    path    => '/sbin:/usr/sbin:/bin:/usr/bin',
    unless  => 'bash -c "source /root/openrc; nova flavor-list | grep -q m1.micro"',
    require => [Class['nova'],Class['openstack::auth_file']],
  }

  Exec<| title=='wait-for-haproxy-keystone-admin-backend' |> ->
  Exec<| title=='create-m1.micro-flavor' |>
  Exec<| title=='wait-for-haproxy-keystone-backend' |> ->
  Exec<| title=='create-m1.micro-flavor' |>
  Exec<| title=='wait-for-haproxy-nova-backend' |> ->
  Exec<| title=='create-m1.micro-flavor' |>
  Class['keystone::roles::admin'] ->
  Exec<| title=='create-m1.micro-flavor' |>

}

if $sahara_hash['enables'] {
  $sahara_scheduler_filters = [ 'DifferentHostFilter' ]
} else {
  $sahara_scheduler_filters = []
}
$scheduler_filters = [
  'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter',
  'ComputeCapabilitiesFilter', 'ImagePropertiesFilter', 'ServerGroupAntiAffinityFilter', 'ServerGroupAffinityFilter',
]

class { 'nova::scheduler::filter':
  cpu_allocation_ratio       => '8.0',
  disk_allocation_ratio      => '1.0',
  ram_allocation_ratio       => '1.0',
  scheduler_host_subset_size => '30',
  scheduler_default_filters  => concat($sahara_scheduler_filters, $scheduler_filters),
}
