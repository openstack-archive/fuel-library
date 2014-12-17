import '../common/globals.pp'

class { 'openstack::controller':
  admin_address                  => $controller_node_address,
  public_address                 => $controller_node_public,
  public_interface               => $public_int,
  private_interface              => $use_neutron ? { true=>false, default=>$fuel_settings['fixed_interface']},
  internal_address               => $controller_node_address,
  service_endpoint               => $controller_node_address,
  floating_range                 => false,
  fixed_range                    => $use_neutron ? { true=>false, default=>$fuel_settings['fixed_network_range'] },
  multi_host                     => $multi_host,
  network_manager                => $network_manager,
  num_networks                   => $use_neutron ? { true=>false, default=>$novanetwork_params['num_networks'] },
  network_size                   => $use_neutron ? { true=>false, default=>$novanetwork_params['network_size'] },
  network_config                 => $use_neutron ? { true=>false, default=>$network_config },
  debug                          => $debug,
  verbose                        => $verbose,
  auto_assign_floating_ip        => $fuel_settings['auto_assign_floating_ip'],
  mysql_root_password            => $mysql_hash['root_password'],
  admin_email                    => $access_hash['email'],
  admin_user                     => $access_hash['user'],
  admin_password                 => $access_hash['password'],
  keystone_db_password           => $keystone_hash['db_password'],
  keystone_admin_token           => $keystone_hash['admin_token'],
  keystone_admin_tenant          => $access_hash['tenant'],
  glance_db_password             => $glance_hash['db_password'],
  glance_user_password           => $glance_hash['user_password'],
  glance_backend                 => $glance_backend,
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
  nova_rate_limits               => $nova_rate_limits,
  ceilometer                     => $ceilometer_hash['enabled'],
  ceilometer_db_password         => $ceilometer_hash['db_password'],
  ceilometer_user_password       => $ceilometer_hash['user_password'],
  ceilometer_metering_secret     => $ceilometer_hash['metering_secret'],
  ceilometer_db_type             => 'mongodb',
  ceilometer_db_host             => mongo_hosts($nodes_hash),
  swift_rados_backend            => $storage_hash['objects_ceph'],
  queue_provider                 => $queue_provider,
  amqp_hosts                     => $amqp_hosts,
  amqp_user                      => $rabbit_hash['user'],
  amqp_password                  => $rabbit_hash['password'],
  rabbitmq_bind_ip_address       => $rabbitmq_bind_ip_address,
  rabbitmq_bind_port             => $rabbitmq_bind_port,
  rabbitmq_cluster_nodes         => $rabbitmq_cluster_nodes,
  export_resources               => false,

  network_provider               => $network_provider,
  neutron_db_password            => $neutron_db_password,
  neutron_user_password          => $neutron_user_password,
  neutron_metadata_proxy_secret  => $neutron_metadata_proxy_secret,
  base_mac                       => $base_mac,

  cinder                         => true,
  cinder_user_password           => $cinder_hash['user_password'],
  cinder_db_password             => $cinder_hash['db_password'],
  cinder_iscsi_bind_addr         => $cinder_iscsi_bind_addr,
  cinder_volume_group            => 'cinder',
  manage_volumes                 => $manage_volumes,
  use_syslog                     => $use_syslog,
  novnc_address                  => $controller_node_public,
  syslog_log_facility_glance     => $syslog_log_facility_glance,
  syslog_log_facility_cinder     => $syslog_log_facility_cinder,
  syslog_log_facility_neutron    => $syslog_log_facility_neutron,
  syslog_log_facility_nova       => $syslog_log_facility_nova,
  syslog_log_facility_keystone   => $syslog_log_facility_keystone,
  syslog_log_facility_ceilometer => $syslog_log_facility_ceilometer,
  cinder_rate_limits             => $cinder_rate_limits,
  horizon_use_ssl                => $horizon_use_ssl,
  nameservers                    => $dns_nameservers,
  primary_controller             => true,
  max_retries                    => $max_retries,
  max_pool_size                  => $max_pool_size,
  max_overflow                   => $max_overflow,
  idle_timeout                   => $idle_timeout,
  nova_report_interval           => $nova_report_interval,
  nova_service_down_time         => $nova_service_down_time,
  cache_server_ip                => [$internal_address],
  memcached_bind_address         => $internal_address,
}

nova_config { 'DEFAULT/resume_guests_state_on_host_boot' : value => hiera('resume_guests_state_on_host_boot') }
nova_config { 'DEFAULT/use_cow_images'                   : value => hiera('use_cow_images') }
nova_config { 'DEFAULT/compute_scheduler_driver'         : value => hiera('compute_scheduler_driver') }
nova_config { 'DEFAULT/ram_weight_multiplier'            : value => '1.0' }

if $sahara_hash['enables'] {
  $sahara_scheduler_filters = [ 'DifferentHostFilter' ]
} else {
  $sahara_scheduler_filters = []
}
$scheduler_filters = [
  'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter',
  'ComputeCapabilitiesFilter', 'ImagePropertiesFilter', 'ServerGroupAntiAffinityFilter', 'ServerGroupAffinityFilter',
]

class { '::nova::scheduler::filter':
  cpu_allocation_ratio       => '8.0',
  disk_allocation_ratio      => '1.0',
  ram_allocation_ratio       => '1.0',
  scheduler_host_subset_size => '30',
  scheduler_default_filters  => $sahara_scheduler_filters + $scheduler_filters,
}
