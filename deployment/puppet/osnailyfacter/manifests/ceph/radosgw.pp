class osnailyfacter::ceph::radosgw {

  notice('MODULAR: ceph/radosgw.pp')

  $storage_hash     = hiera_hash('storage', {})
  $keystone_hash    = hiera_hash('keystone', {})
  $management_vip   = hiera('management_vip')
  $service_endpoint = hiera('service_endpoint')
  $radosgw_large_pool_name = '.rgw'
  $mon_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $external_lb      = hiera('external_lb', false)
  $ssl_hash         = hiera_hash('use_ssl', {})
  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_url      = "${admin_identity_protocol}://${admin_identity_address}:35357"

  if $storage_hash['objects_ceph'] {
    $ceph_primary_monitor_node = hiera('ceph_primary_monitor_node')
    $primary_mons              = keys($ceph_primary_monitor_node)
    $primary_mon               = $ceph_primary_monitor_node[$primary_mons[0]]['name']

    prepare_network_config(hiera_hash('network_scheme', {}))
    $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
    $ceph_public_network  = get_network_role_property('ceph/public', 'network')
    $rgw_ip_address       = get_network_role_property('ceph/radosgw', 'ipaddr')

    # Listen directives with host required for ip_based vhosts
    class { '::osnailyfacter::apache':
      listen_ports => hiera_array('apache_ports', ['0.0.0.0:80', '0.0.0.0:8888']),
    }

    if ($::osfamily == 'Debian'){
      apache::mod {'rewrite': }
      apache::mod {'proxy': }
      apache::mod {'proxy_fcgi': }
    }
    include ::tweaks::apache_wrappers

    include ::ceph::params

    class { '::ceph::radosgw':
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
      rgw_keystone_url                 => $admin_identity_url,
      rgw_keystone_admin_token         => $keystone_hash['admin_token'],
      rgw_keystone_token_cache_size    => '10',
      rgw_keystone_accepted_roles      => '_member_, Member, admin, swiftoperator',
      rgw_keystone_revocation_interval => '1000000',
      rgw_s3_auth_use_keystone         => false,
      rgw_nss_db_path                  => '/etc/ceph/nss',
      rgw_large_pool_name              => $radosgw_large_pool_name,
      rgw_large_pool_pg_nums           => pick($storage_hash['per_pool_pg_nums'][$radosgw_large_pool_name], '512'),

      #rgw Log settings
      use_syslog                       => hiera('use_syslog', true),
      syslog_facility                  => hiera('syslog_log_facility_ceph', 'LOG_LOCAL0'),
      syslog_level                     => hiera('syslog_log_level_ceph', 'info'),
    }

    Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
      cwd  => '/root',
    }
  }

}
