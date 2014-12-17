class { 'openstack::heat' :
  external_ip         => $controller_node_public,

  keystone_host       => $controller_node_address,
  keystone_user       => 'heat',
  keystone_password   => $heat_hash['user_password'],
  keystone_tenant     => 'services',

  keystone_ec2_uri    => "http://${controller_node_address}:5000/v2.0",

  rpc_backend         => 'heat.openstack.common.rpc.impl_kombu',
  amqp_hosts          => [$amqp_hosts],
  amqp_user           => $rabbit_hash['user'],
  amqp_password       => $rabbit_hash['password'],

  sql_connection      =>
    "mysql://heat:${heat_hash['db_password']}@${$controller_node_address}/heat?read_timeout=60",
  db_host             => $controller_node_address,
  db_password         => $heat_hash['db_password'],
  max_retries         => $max_retries,
  max_pool_size       => $max_pool_size,
  max_overflow        => $max_overflow,
  idle_timeout        => $idle_timeout,

  debug               => $debug,
  verbose             => $verbose,
  use_syslog          => $use_syslog,
  syslog_log_facility => $syslog_log_facility_heat,

  auth_encryption_key => $heat_hash['auth_encryption_key'],
}
