notice('MODULAR: ceph/radosgw.pp')

$storage_hash   = hiera('storage', {})
$controllers    = hiera('controllers')
$use_neutron    = hiera('use_neutron')
$public_vip     = hiera('public_vip')
$keystone_hash  = hiera('keystone', {})
$management_vip = hiera('management_vip')

if (!empty(filter_nodes(hiera('nodes'), 'role', 'ceph-osd')) or
  $storage_hash['volumes_ceph'] or
  $storage_hash['images_ceph'] or
  $storage_hash['objects_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}

if $use_ceph and $storage_hash['objects_ceph'] {
  $primary_mons   = $controllers
  $primary_mon    = $controllers[0]['name']

  if ($use_neutron) {
    prepare_network_config(hiera('network_scheme', {}))
    $ceph_cluster_network = get_network_role_property('storage', 'cidr')
    $ceph_public_network  = get_network_role_property('management', 'cidr')
  } else {
    $ceph_cluster_network = hiera('storage_network_range')
    $ceph_public_network = hiera('management_network_range')
  }

  # Apache and listen ports
  class { 'osnailyfacter::apache':
    listen_ports => hiera_array('apache_ports', ['80', '8888']),
  }
  if ($::osfamily == 'Debian'){
    apache::mod {'rewrite': }
    apache::mod {'proxy_fcgi': }
  }

  include ceph::params

  class { 'ceph::radosgw':
    # SSL
    use_ssl                          => false,

    # Ceph
    primary_mon                      => $primary_mon,
    pub_ip                           => $public_vip,
    adm_ip                           => $management_vip,
    int_ip                           => $management_vip,

    # RadosGW settings
    rgw_host                         => $::hostname,
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
    rgw_keystone_url                 => "${management_vip}:35357",
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
