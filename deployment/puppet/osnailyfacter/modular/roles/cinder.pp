import '../globals.pp'

include keystone::python

#FIXME(bogdando) notify services on python-amqp update, if needed
package { 'python-amqp':
  ensure => 'present'
}

if member($roles, 'controller') or member($roles, 'primary-controller') {
  $bind_host = '0.0.0.0'
} else {
  $bind_host = false
}

$cinder_db_password = $cinder_hash['db_password']
$sql_connection = "mysql://cinder:${cinder_db_password}@${controller_node_address}/cinder?charset=utf8&read_timeout=60"
$glance_api_servers = "${controller_node_address}:9292"

class { 'openstack::cinder':
  sql_connection       => $sql_connection,
  glance_api_servers   => $glance_api_servers,
  queue_provider       => $queue_provider,
  amqp_hosts           => $amqp_hosts,
  amqp_user            => $rabbit_hash['user'],
  amqp_password        => $rabbit_hash['password'],
  bind_host            => $bind_host,
  volume_group         => 'cinder',
  manage_volumes       => $manage_volumes,
  iser                 => $storage_hash['iser'],
  enabled              => true,
  auth_host            => $controller_node_address,
  iscsi_bind_host      => $cinder_iscsi_bind_addr,
  cinder_user_password => $cinder_hash['user_password'],
  syslog_log_facility  => $syslog_log_facility_cinder,
  debug                => $debug,
  verbose              => $verbose,
  use_syslog           => $use_syslog,
  max_retries          => $max_retries,
  max_pool_size        => $max_pool_size,
  max_overflow         => $max_overflow,
  idle_timeout         => $idle_timeout,
  ceilometer           => $ceilometer_hash['enabled'],
  vmware_host_ip       => $vcenter_hash['host_ip'],
  vmware_host_username => $vcenter_hash['vc_user'],
  vmware_host_password => $vcenter_hash['vc_password']
}
