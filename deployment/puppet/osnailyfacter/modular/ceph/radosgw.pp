notice('MODULAR: ceph/radosgw.pp')

$gateway_name                     = 'radosgw.gateway'
$storage_hash                     = hiera('storage', {})
$rgw_log_file                     = '/var/log/ceph/radosgw.log'
$use_syslog                       = hiera('use_syslog', true)
$rgw_large_pool_name              = ".rgw"
$rgw_large_pool_pg_nums           = pick($storage_hash['per_pool_pg_nums'][$radosgw_large_pool_name], '512')
$keystone_hash                    = hiera('keystone', {})
$rgw_port                         = '6780'
$swift_endpoint_port              = '8080'
$rgw_keystone_accepted_roles      = '_member_, Member, admin, swiftoperator'
$rgw_keystone_revocation_interval = '1000000'
$rgw_frontends                    = 'fastcgi socket_port=9000 socket_host=127.0.0.1'
$rgw_keystone_token_cache_size    = '10'
$external_lb                      = hiera('external_lb', false)
$ssl_hash                         = hiera_hash('use_ssl', {})
$management_vip                   = hiera('management_vip')
$service_endpoint                 = hiera('service_endpoint')
$haproxy_stats_url                = "http://${service_endpoint}:10000/;csv"

prepare_network_config(hiera_hash('network_scheme'))
$ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
$ceph_public_network  = get_network_role_property('ceph/public', 'network')

$mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
$primary_mon = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_primary_monitor_node'), 'ceph/public')
$mon_ips = join(values($mon_address_map), ',')
$mon_hosts = join(keys($mon_address_map), ',')

ceph::key { "client.${gateway_name}":
  keyring_path => "/etc/ceph/client.${gateway_name}",
  secret       => hiera('admin_key'),
  cap_mon      => 'allow rw',
  cap_osd      => 'allow rwx',
  inject       => true,
}

class { 'ceph':
  fsid                      => hiera('fsid'),
  mon_initial_members       => $mon_initial_members,
  mon_host                  => $mon_host,
  cluster_network           => $ceph_cluster_network,
  public_network            => $ceph_public_network,
  osd_pool_default_size     => $osd_pool_default_size,
  osd_pool_default_pg_num   => $osd_pool_default_pg_num,
  osd_pool_default_pgp_num  => $osd_pool_default_pgp_num,
  osd_pool_default_min_size => $osd_pool_default_min_size,
  osd_journal_size          => $osd_journal_size,
}

ceph_config {
  'globals/osd_mkfs_type'                     : value => 'xfs';
  'global/filestore_xattr_use_omap'           : value => true;
  'global/osd_recovery_max_active'            : value => '1';
  'global/osd_max_backfills'                  : value => '1';
  'global/max_open_files'                     : value => '1';
  'client/rbd_cache_writethrough_until_flush' : value => true;
  'client/rbd_cache'                          : value => true;
  'global/log_to_syslog'                      : value => true;
  'global/log_to_syslog_level'                : value => 'info';
  'global/log_to_syslog_facility'             : value => 'LOG_LOCAL0';
}

include ::tweaks::apache_wrappers
include ::ceph::params

if $external_lb {
  Haproxy_backend_status<||> {
    provider => 'http',
  }
  $internal_auth_protocol  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address   = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_auth_url       = "${internal_auth_protocol}://${internal_auth_address}:5000"
  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_url      = "${admin_identity_protocol}://${admin_identity_address}:35357"
}

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '200',
  step  => '6',
  url   => $external_lb ? {
    default => $haproxy_stats_url,
    true    => $admin_identity_url,
  },
}

haproxy_backend_status { 'keystone-public' :
  name  => 'keystone-1',
  count => '200',
  step  => '6',
  url   => $external_lb ? {
    default => $haproxy_stats_url,
    true    => $internal_auth_url,
  },
}

Haproxy_backend_status['keystone-admin']  -> Ceph::Rgw::Keystone['radosgw.gateway']
Haproxy_backend_status['keystone-public'] -> Ceph::Rgw::Keystone['radosgw.gateway']

ceph::rgw { $gateway_name:
  rgw_print_continue => true,
  keyring_path       => "/etc/ceph/client.${gateway_name}",
  log_file           => "/var/log/ceph/${gateway_name}.log",
  rgw_data           => "/var/lib/ceph/radosgw-${gateway_name}",
  rgw_dns_name       => "*.${::domain}",
}

ceph::rgw::keystone { $gateway_name:
  rgw_keystone_url                 => "${service_endpoint}:35357",
  rgw_keystone_admin_token         => $keystone_hash['admin_token'],
  rgw_keystone_token_cache_size    => $rgw_keystone_token_cache_size,
  rgw_keystone_accepted_roles      => $rgw_keystone_accepted_roles,
  rgw_keystone_revocation_interval => $rgw_keystone_revocation_interval,
}  

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  cwd  => '/root',
}

file { "/var/lib/ceph/radosgw/ceph-${gateway_name}":
  ensure => directory,
}

###########################################################
# THIS SHOULD BE FIXED
# we cannot reuse this class, because it breaks our apache
###########################################################

#ceph::rgw::apache {'radosgw':
#  admin_email => 'root@localhost',
#  docroot => '/var/www/radosgw',
#  fcgi_file => '/var/www/radosgw/s3gw.fcgi',
#  rgw_dns_name => $::fqdn,
#  rgw_port => 6780,
#  rgw_socket_path => '/tmp/radosgw.sock',
#  syslog => true,
#  ceph_apache_repo => false,
#}

  class { 'osnailyfacter::apache':
    purge_configs => false,
    listen_ports  => hiera_array('apache_ports', ['0.0.0.0:80']),
  }

  include ::osnailyfacter::apache_mpm
  include ::apache::mod::rewrite

  ceph_config {
    "client.${gateway_name}/rgw_frontends": value => $rgw_frontends;
  }

  apache::vhost { $gateway_name:
    docroot      => '/var/www/radosgw',
    port         => $rgw_port,
    servername   => $::fqdn,
    rewrite_rule => '.* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
    setenv       => 'proxy-nokeepalive 1',
    proxy_pass   => [{ 'path' => '/', 'url' => 'fcgi://127.0.0.1:9000/' }],
  }

  firewall {'012 RadosGW allow':
    chain   => 'INPUT',
    dport   => [ $rgw_port, $swift_endpoint_port ],
    proto   => 'tcp',
    action  => accept,
  }

  if ! $use_syslog {
    ceph_config {
      "client.radosgw.gateway/log_file":      value => $rgw_log_file;
      "client.radosgw.gateway/log_to_syslog": value => $use_syslog;
    }
  }

  exec { "Create ${rgw_large_pool_name} pool":
    command => "ceph -n client.radosgw.gateway osd pool create ${rgw_large_pool_name} ${rgw_large_pool_pg_nums} ${rgw_large_pool_pg_nums}",
    unless  => "rados lspools | grep '^${rgw_large_pool_name}$'",
  }

