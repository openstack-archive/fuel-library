class osnailyfacter::ceph::radosgw {

  notice('MODULAR: ceph/radosgw.pp')

  $gateway_name                     = 'radosgw.gateway'
  $storage_hash                     = hiera('storage', {})
  $radosgw_key                      = $storage_hash['radosgw_key']
  $fsid                             = $storage_hash['fsid']
  $rgw_log_file                     = '/var/log/ceph/radosgw.log'
  $use_syslog                       = hiera('use_syslog', true)
  $rgw_large_pool_name              = '.rgw'
  $rgw_large_pool_pg_nums           = pick($storage_hash['per_pool_pg_nums'][$rgw_large_pool_name], '512')
  $keystone_hash                    = hiera('keystone', {})
  $rgw_keystone_accepted_roles      = pick($storage_hash['radosgw_keystone_accepted_roles'], '_member_, Member, admin, swiftoperator')
  $rgw_keystone_revocation_interval = '1000000'
  $rgw_keystone_token_cache_size    = '10'
  $rgw_init_timeout                 = pick($storage_hash['rgw_init_timeout'], '360000')
  $auth_s3_keystone_ceph            = pick($storage_hash['auth_s3_keystone_ceph'], false)
  $service_endpoint                 = hiera('service_endpoint')
  $management_vip                   = hiera('management_vip')

  $ssl_hash                = hiera_hash('use_ssl', {})
  $admin_identity_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_url      = "${admin_identity_protocol}://${admin_identity_address}:35357"

  prepare_network_config(hiera_hash('network_scheme'))
  $ceph_cluster_network = get_network_role_property('ceph/replication', 'network')
  $ceph_public_network  = get_network_role_property('ceph/public', 'network')

  $mon_address_map = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')
  $mon_ips         = join(sorted_hosts($mon_address_map, 'ip'), ',')
  $mon_hosts       = join(sorted_hosts($mon_address_map, 'host'), ',')

  if $storage_hash['objects_ceph'] {

    if empty($fsid) {
      fail('Please provide fsid')
    }
    if empty($radosgw_key) {
      fail('Please provide radosgw_key')
    }

    ceph::key { "client.${gateway_name}":
      keyring_path => "/etc/ceph/client.${gateway_name}",
      user         => 'ceph',
      group        => 'ceph',
      secret       => $radosgw_key,
      cap_mon      => 'allow rw',
      cap_osd      => 'allow rwx',
      inject       => true,
    }

    class { 'ceph':
      fsid => $fsid,
    }

    include ::ceph::params

#######################################
# TODO (omolchanov): Remove template once we switch to systemd
#######################################

    file { '/etc/init/radosgw.conf':
      ensure  => present,
      content => template('osnailyfacter/radosgw-init.erb'),
      before  => Ceph::Rgw[$gateway_name],
    }
#######################################

    ceph::rgw { $gateway_name:
      frontend_type      => 'civetweb',
      rgw_frontends      => 'civetweb port=7480',
      rgw_print_continue => true,
      keyring_path       => "/etc/ceph/client.${gateway_name}",
      rgw_data           => "/var/lib/ceph/radosgw-${gateway_name}",
      rgw_dns_name       => "*.${::domain}",
      log_file           => undef,
    }

    ceph::rgw::keystone { $gateway_name:
      rgw_keystone_url                 => $admin_identity_url,
      rgw_keystone_admin_token         => $keystone_hash['admin_token'],
      rgw_keystone_token_cache_size    => $rgw_keystone_token_cache_size,
      rgw_keystone_accepted_roles      => $rgw_keystone_accepted_roles,
      rgw_s3_auth_use_keystone         => $auth_s3_keystone_ceph,
      use_pki                          => false,
    }

    file { "/var/lib/ceph/radosgw/ceph-${gateway_name}":
      ensure => directory,
    }

    if ! $use_syslog {
      ceph_config {
        "client.${gateway_name}/log_file":      value => $rgw_log_file;
        "client.${gateway_name}/log_to_syslog": value => $use_syslog;
      }
    }

    ceph_config {
      "client.${gateway_name}/rgw_init_timeout": value => $rgw_init_timeout;
    }

    exec { "Create ${rgw_large_pool_name} pool":
      command => "ceph -n client.${gateway_name} osd pool create ${rgw_large_pool_name} ${rgw_large_pool_pg_nums} ${rgw_large_pool_pg_nums}",
      path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin',
      unless  => "rados lspools | grep '^${rgw_large_pool_name}$'",
    }

    Ceph::Key["client.${gateway_name}"] -> Exec["Create ${rgw_large_pool_name} pool"]
  }

}
