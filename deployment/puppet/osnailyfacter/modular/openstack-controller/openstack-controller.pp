notice('MODULAR: openstack-controller.pp')

$nova_rate_limits               = hiera('nova_rate_limits')
$primary_controller             = hiera('primary_controller')
$use_neutron                    = hiera('use_neutron') # neutron
$neutron_nsx_config             = hiera('nsx_plugin')
$cinder_rate_limits             = hiera('cinder_rate_limits')
$nova_report_interval           = hiera('nova_report_interval')
$nova_service_down_time         = hiera('nova_service_down_time')
$use_syslog                     = hiera('use_syslog', true)
$syslog_log_facility_glance     = hiera('syslog_log_facility_glance', 'LOG_LOCAL2')
$syslog_log_facility_cinder     = hiera('syslog_log_facility_cinder', 'LOG_LOCAL3')
$syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
$syslog_log_facility_nova       = hiera('syslog_log_facility_nova','LOG_LOCAL6')
$syslog_log_facility_keystone   = hiera('syslog_log_facility_keystone', 'LOG_LOCAL7')
$syslog_log_facility_ceilometer = hiera('syslog_log_facility_ceilometer','LOG_LOCAL0')
$management_vip                 = hiera('management_vip')
$floating_hash = {}

$network_config = {
  'vlan_start'     => $vlan_start,
}

if $use_neutron {
  include l23network::l2
  $novanetwork_params        = {}
  $neutron_config            = hiera('quantum_settings')
  $network_provider          = 'neutron'
  $neutron_db_password       = $neutron_config['database']['passwd']
  $neutron_user_password     = $neutron_config['keystone']['admin_password']
  $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
  $base_mac                  = $neutron_config['L2']['base_mac']
  if $neutron_nsx_config['metadata']['enabled'] {
    $use_vmware_nsx     = true
  }
} else {
  $floating_ips_range = hiera('floating_network_range')
  $neutron_config     = {}
  $novanetwork_params = hiera('novanetwork_parameters')
  $network_size       = $novanetwork_params['network_size']
  $num_networks       = $novanetwork_params['num_networks']
  $vlan_start         = $novanetwork_params['vlan_start']
  $network_provider   = 'nova'
}

$storage_address                = hiera('storage_address')
$cinder_hash                    = hiera('cinder', {})
$nodes_hash                     = hiera('nodes', {})
$mysql_hash                     = hiera('mysql', {})
$controllers                    = hiera('controllers')
$access_hash                    = hiera('access', {})
$keystone_hash                  = hiera('keystone', {})
$glance_hash                    = hiera('glance', {})
$storage_hash                   = hiera('storage', {})
$nova_hash                      = hiera('nova', {})
$internal_address               = hiera('internal_address')
$rabbit_hash                    = hiera('rabbit', {})
$ceilometer_hash                = hiera('ceilometer',{})
$mongo_hash                     = hiera('mongo', {})
$controller_internal_addresses  = nodes_to_hash($controllers,'name','internal_address')
$controller_nodes               = ipsort(values($controller_internal_addresses))
$controller_hostnames           = keys($controller_internal_addresses)
$cinder_iscsi_bind_addr         = $storage_address
$roles                          = node_roles($nodes_hash, hiera('uid'))

if $internal_address in $controller_nodes {
  # prefer local MQ broker if it exists on this node
  $amqp_nodes = concat(['127.0.0.1'], fqdn_rotate(delete($controller_nodes, $internal_address)))
} else {
  $amqp_nodes = fqdn_rotate($controller_nodes)
}
$amqp_port = '5673'
$amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.join ',' %>")

# RabbitMQ server configuration
$rabbitmq_bind_ip_address = 'UNSET'              # bind RabbitMQ to 0.0.0.0
$rabbitmq_bind_port = $amqp_port
$rabbitmq_cluster_nodes = $controller_hostnames  # has to be hostnames

if ($storage_hash['images_ceph']) {
  $glance_backend = 'ceph'
  $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
} elsif ($storage_hash['images_vcenter']) {
  $glance_backend = 'vmware'
  $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
} else {
  $glance_backend = 'swift'
  $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
}

# Determine who should get the volume service

if (member($roles, 'cinder') and $storage_hash['volumes_lvm']) {
  $manage_volumes = 'iscsi'
} elsif (member($roles, 'cinder') and $storage_hash['volumes_vmdk']) {
  $manage_volumes = 'vmdk'
} elsif ($storage_hash['volumes_ceph']) {
  $manage_volumes = 'ceph'
} else {
  $manage_volumes = false
}

if !$ceilometer_hash {
  $ceilometer_hash = {
    enabled         => false,
    db_password     => 'ceilometer',
    user_password   => 'ceilometer',
    metering_secret => 'ceilometer',
  }
  $ext_mongo = false
} else {
  # External mongo integration
  if $mongo_hash['enabled'] {
    $ext_mongo_hash         = hiera('external_mongo')
    $ceilometer_db_user     = $ext_mongo_hash['mongo_user']
    $ceilometer_db_password = $ext_mongo_hash['mongo_password']
    $ceilometer_db_name     = $ext_mongo_hash['mongo_db_name']
    $ext_mongo              = true
  } else {
    $ceilometer_db_user     = 'ceilometer'
    $ceilometer_db_password = $ceilometer_hash['db_password']
    $ceilometer_db_name     = 'ceilometer'
    $ext_mongo              = false
    $ext_mongo_hash         = {}
  }
}

if $ext_mongo {
  $mongo_hosts = $ext_mongo_hash['hosts_ip']
  if $ext_mongo_hash['mongo_replset'] {
    $mongo_replicaset = $ext_mongo_hash['mongo_replset']
  } else {
    $mongo_replicaset = undef
  }
} elsif $ceilometer_hash['enabled'] {
  $mongo_hosts = mongo_hosts($nodes_hash)
  if size(mongo_hosts($nodes_hash, 'array', 'mongo')) > 1 {
    $mongo_replicaset = 'ceilometer'
  } else {
    $mongo_replicaset = undef
  }
}

# SQLAlchemy backend configuration
$max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
$max_overflow = min($::processorcount * 5 + 0, 60 + 0)
$max_retries = '-1'
$idle_timeout = '3600'

# TODO: openstack_version is confusing, there's such string var in hiera and hardcoded hash
$hiera_openstack_version = hiera('openstack_version')
$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

class { '::openstack::controller':
  private_interface              => $use_neutron ? { true =>false, default =>hiera('fixed_interface')},
  public_interface               => hiera('public_int', undef),
  public_address                 => hiera('public_vip'),    # It is feature for HA mode.
  internal_address               => $management_vip,  # All internal traffic goes
  admin_address                  => $management_vip,  # through load balancer.
  floating_range                 => $use_neutron ? { true =>$floating_hash, default  =>false},
  fixed_range                    => $use_neutron ? { true =>false, default =>hiera('fixed_network_range')},
  multi_host                     => true,
  network_config                 => $network_config,
  num_networks                   => $num_networks,
  network_size                   => $network_size,
  network_manager                => "nova.network.manager.${novanetwork_params['network_manager']}",
  verbose                        => true,
  debug                          => hiera('debug', true),
  auto_assign_floating_ip        => hiera('auto_assign_floating_ip', false),
  mysql_root_password            => $mysql_hash[root_password],
  custom_mysql_setup_class       => 'galera',
  galera_cluster_name            => 'openstack',
  primary_controller             => $primary_controller,
  galera_node_address            => $internal_address,
  galera_nodes                   => $controller_nodes,
  novnc_address                  => $internal_address,
  mysql_skip_name_resolve        => true,
  admin_email                    => $access_hash[email],
  admin_user                     => $access_hash[user],
  admin_password                 => $access_hash[password],
  keystone_db_password           => $keystone_hash[db_password],
  keystone_admin_token           => $keystone_hash[admin_token],
  keystone_admin_tenant          => $access_hash[tenant],
  glance_db_password             => $glance_hash[db_password],
  glance_user_password           => $glance_hash[user_password],
  glance_api_servers             => undef,
  glance_image_cache_max_size    => $glance_hash[image_cache_max_size],
  glance_vcenter_host            => $storage_hash['vc_host'],
  glance_vcenter_user            => $storage_hash['vc_user'],
  glance_vcenter_password        => $storage_hash['vc_password'],
  glance_vcenter_datacenter      => $storage_hash['vc_datacenter'],
  glance_vcenter_datastore       => $storage_hash['vc_datastore'],
  glance_vcenter_image_dir       => $storage_hash['vc_image_dir'],
  nova_db_password               => $nova_hash[db_password],
  nova_user_password             => $nova_hash[user_password],
  queue_provider                 => 'rabbitmq',
  amqp_hosts                     => $amqp_hosts,
  amqp_user                      => $rabbit_hash['user'],
  amqp_password                  => $rabbit_hash['password'],
  rabbit_ha_queues               => true,
  rabbitmq_bind_ip_address       => $rabbitmq_bind_ip_address,
  rabbitmq_bind_port             => $rabbitmq_bind_port,
  rabbitmq_cluster_nodes         => $rabbitmq_cluster_nodes,
  cache_server_ip                => $controller_nodes,
  memcached_bind_address         => $internal_address,
  export_resources               => false,
  api_bind_address               => $internal_address,
  db_host                        => $management_vip,
  service_endpoint               => $management_vip,
  glance_backend                 => $glance_backend,
  known_stores                   => $glance_known_stores,
  #require                        => Service['keepalived'],
  network_provider               => $network_provider,
  neutron_db_user                => 'neutron',
  neutron_db_password            => $neutron_db_password,
  neutron_db_dbname              => 'neutron',
  neutron_user_password          => $neutron_user_password,
  neutron_metadata_proxy_secret  => $neutron_metadata_proxy_secret,
  neutron_ha_agents              => $primary_controller ? {true => 'primary', default  => 'slave'},
  segment_range                  => undef,
  tenant_network_type            => undef,
  create_networks                => $primary_controller,
  #
  cinder                         => true,
  cinder_iscsi_bind_addr         => $cinder_iscsi_bind_addr,
  cinder_user_password           => $cinder_hash[user_password],
  cinder_db_password             => $cinder_hash[db_password],
  manage_volumes                 => $manage_volumes,
  nv_physical_volume             => undef,
  cinder_volume_group            => 'cinder',
  #
  ceilometer                     => $ceilometer_hash[enabled],
  ceilometer_db_user             => $ceilometer_db_user,
  ceilometer_db_password         => $ceilometer_db_password,
  ceilometer_user_password       => $ceilometer_hash[user_password],
  ceilometer_metering_secret     => $ceilometer_hash[metering_secret],
  ceilometer_db_dbname           => $ceilometer_db_dbname,
  ceilometer_db_type             => 'mongodb',
  ceilometer_db_host             => $mongo_hosts,
  swift_rados_backend            => $storage_hash['objects_ceph'],
  ceilometer_ext_mongo           => $ext_mongo,
  mongo_replicaset               => $mongo_replicaset,
  #
  # turn on SWIFT_ENABLED option for Horizon dashboard
  swift                          => $glance_backend ? { 'swift' => true, default  => false },
  use_syslog                     => $use_syslog,
  syslog_log_facility_glance     => $syslog_log_facility_glance,
  syslog_log_facility_cinder     => $syslog_log_facility_cinder,
  syslog_log_facility_nova       => $syslog_log_facility_nova,
  syslog_log_facility_keystone   => $syslog_log_facility_keystone,
  syslog_log_facility_ceilometer => $syslog_log_facility_ceilometer,
  cinder_rate_limits             => $cinder_rate_limits,
  nova_rate_limits               => $nova_rate_limits,
  nova_report_interval           => $nova_report_interval,
  nova_service_down_time         => $nova_service_down_time,
  horizon_use_ssl                => hiera('horizon_use_ssl', false),
  ha_mode                        => true,
  nameservers                    => hiera('dns_nameservers'),
  # SQLALchemy backend
  max_retries                    => $max_retries,
  max_pool_size                  => $max_pool_size,
  max_overflow                   => $max_overflow,
  idle_timeout                   => $idle_timeout,
}

package { 'socat': ensure => present }

#TODO: PUT this configuration stanza into nova class
nova_config { 'DEFAULT/use_cow_images':                   value => hiera('use_cow_images')}

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

  exec { 'wait-for-haproxy-mysql-backend':
    command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep '^mysqld,' | egrep -v ',FRONTEND,|,BACKEND,' | grep -qv ',INI,' &&
                  echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^mysqld,BACKEND,.*,UP,'",
    path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    try_sleep => 5,
    tries     => 60,
    require   => Package['socat'],
  }

  Package['socat'] -> Exec['wait-for-haproxy-mysql-backend']
  Class['galera::status'] -> Exec['wait-for-haproxy-mysql-backend']
  Exec<| title == 'wait-for-synced-state' |> -> Exec['wait-for-haproxy-mysql-backend']
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'keystone-manage db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'glance-manage db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'cinder-manage db_sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'nova-db-sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'heat-dbsync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'ceilometer-dbsync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'neutron-db-sync' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-scheduler' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-volume' |>
  Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-api' |>

  Class['keystone'] -> Exec<| title=='wait-for-haproxy-keystone-backend' |>
  Class['keystone'] -> Exec<| title=='wait-for-haproxy-keystone-admin-backend' |>

  exec { 'wait-for-haproxy-nova-backend':
    command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep '^nova-api-2,' | egrep -v ',FRONTEND,|,BACKEND,' | grep -qv ',INI,' &&
                  echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^nova-api-2,BACKEND,.*,UP,'",
    path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    try_sleep => 5,
    tries     => 60,
    require   => Package['socat'],
  }

  Class['nova::api', 'nova::keystone::auth'] -> Exec<| title=='wait-for-haproxy-nova-backend' |>

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

  if ! $use_neutron {
    nova_floating_range { $floating_ips_range:
      ensure          => 'present',
      pool            => 'nova',
      username        => $access_hash[user],
      api_key         => $access_hash[password],
      auth_method     => 'password',
      auth_url        => "http://${management_vip}:5000/v2.0/",
      authtenant_name => $access_hash[tenant],
      api_retries     => 10,
    }
    Exec<| title=='wait-for-haproxy-nova-backend' |> ->
    Nova_floating_range <| |>

    Exec<| title=='wait-for-haproxy-keystone-backend' |> ->
    Nova_floating_range <| |>

    Exec<| title=='wait-for-haproxy-keystone-admin-backend' |> ->
    Nova_floating_range <| |>
  }
}

