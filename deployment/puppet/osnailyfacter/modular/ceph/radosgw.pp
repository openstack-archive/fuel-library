notice('MODULAR: ceph/radosgw.pp')

$storage_hash     = hiera('storage', {})
$use_neutron      = hiera('use_neutron')
$public_vip       = hiera('public_vip')
$keystone_hash    = hiera('keystone', {})
$management_vip   = hiera('management_vip')
$service_endpoint = hiera('service_endpoint')
$public_ssl_hash  = hiera('public_ssl')
$mon_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')

if ($storage_hash['volumes_ceph'] or
  $storage_hash['images_ceph'] or
  $storage_hash['objects_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}

if $use_ceph and $storage_hash['objects_ceph'] {
  $ceph_primary_monitor_node = hiera('ceph_primary_monitor_node')
  $primary_mons              = keys($ceph_primary_monitor_node)
  $primary_mon               = $ceph_primary_monitor_node[$primary_mons[0]]['name']

  prepare_network_config(hiera_hash('network_scheme'))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')
  $rgw_ip_address       = get_network_role_property('ceph/radosgw', 'ipaddr')

  # Apache and listen ports
  class { 'osnailyfacter::apache':
    listen_ports => hiera_array('apache_ports', ['80', '8888']),
  }
  if ($::osfamily == 'Debian'){
    apache::mod {'rewrite': }
    apache::mod {'proxy_fcgi': }
  }
  include ::tweaks::apache_wrappers
  include ceph::params

  $haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

  haproxy_backend_status { 'keystone-admin' :
    name  => 'keystone-2',
    count => '200',
    step  => '6',
    url   => $haproxy_stats_url,
  }

  haproxy_backend_status { 'keystone-public' :
    name  => 'keystone-1',
    count => '200',
    step  => '6',
    url   => $haproxy_stats_url,
  }

  Haproxy_backend_status['keystone-admin']  -> Class ['ceph::keystone']
  Haproxy_backend_status['keystone-public'] -> Class ['ceph::keystone']

  class { 'ceph::radosgw':
    # SSL
    use_ssl                          => false,
    public_ssl                       => $public_ssl_hash['services'],

    # Ceph
    primary_mon                      => $primary_mon,
    pub_ip                           => $public_vip,
    adm_ip                           => $management_vip,
    int_ip                           => $management_vip,

    # RadosGW settings
    rgw_host                         => $::hostname,
    rgw_ip                           => $rgw_ip_address,
    rgw_port                         => '6780',
    swift_endpoint_port              => '8080',
    rgw_keyring_path                 => '/etc/ceph/keyring.radosgw.gateway',
    rgw_socket_path                  => '/tmp/radosgw.sock',
    rgw_frontends                    => 'fastcgi socket_port=9000 socket_host=127.0.0.1',
    rgw_log_file                     => '/var/log/ceph/radosgw.log',
    rgw_data                         => '/var/lib/ceph/radosgw',
    rgw_dns_name                     => "*.${::domain}",
    rgw_print_continue               => true,

    #rgw Keystone settings
    rgw_use_pki                      => false,
    rgw_use_keystone                 => true,
    rgw_keystone_url                 => "${service_endpoint}:35357",
    rgw_keystone_admin_token         => $keystone_hash['admin_token'],
    rgw_keystone_token_cache_size    => '10',
    rgw_keystone_accepted_roles      => '_member_, Member, admin, swiftoperator',
    rgw_keystone_revocation_interval => '1000000',
    rgw_nss_db_path                  => '/etc/ceph/nss',

    #rgw Log settings
    use_syslog                       => hiera('use_syslog', true),
    syslog_facility                  => hiera('syslog_log_facility_ceph', 'LOG_LOCAL0'),
    syslog_level                     => hiera('syslog_log_level_ceph', 'info'),
  }

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
         cwd  => '/root',
  }
}
