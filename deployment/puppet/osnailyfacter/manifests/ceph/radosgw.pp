class osnailyfacter::ceph::radosgw {

  notice('MODULAR: ceph/radosgw.pp')

  $gateway_name                     = 'radosgw.gateway'
  $storage_hash                     = hiera('storage', {})
  $radosgw_key                      = pick($storage_hash['radosgw_key'], 'AQCTg71RsNIHORAAW+O6FCMZWBjmVfMIPk3MhQ==')
  $fsid                             = pick($storage_hash['fsid'], '066F558C-6789-4A93-AAF1-5AF1BA01A3AD')
  $rgw_log_file                     = '/var/log/ceph/radosgw.log'
  $use_syslog                       = hiera('use_syslog', true)
  $rgw_large_pool_name              = '.rgw'
  $rgw_large_pool_pg_nums           = pick($storage_hash['per_pool_pg_nums'][$rgw_large_pool_name], '512')
  $keystone_hash                    = hiera('keystone', {})
  $rgw_keystone_accepted_roles      = pick($storage_hash['radosgw_keystone_accepted_roles'], '_member_, Member, admin, swiftoperator')
  $rgw_keystone_revocation_interval = '1000000'
  $rgw_keystone_token_cache_size    = '10'
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
  $mon_ips         = join(values($mon_address_map), ',')
  $mon_hosts       = join(keys($mon_address_map), ',')

  if $storage_hash['objects_ceph'] {
    ceph::key { "client.${gateway_name}":
      keyring_path => "/etc/ceph/client.${gateway_name}",
      secret       => $radosgw_key,
      cap_mon      => 'allow rw',
      cap_osd      => 'allow rwx',
      inject       => true,
    }

    class { 'ceph':
      fsid => $fsid,
    }

    include ::tweaks::apache_wrappers
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
      frontend_type      => 'apache-proxy-fcgi',
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
      rgw_keystone_revocation_interval => $rgw_keystone_revocation_interval,
    }

    file { "/var/lib/ceph/radosgw/ceph-${gateway_name}":
      ensure => directory,
    }

    ceph::rgw::apache_proxy_fcgi { 'radosgw.gateway':
      docroot              => '/var/www/radosgw',
      rgw_port             => '6780',
      apache_purge_configs => false,
      apache_purge_vhost   => false,
      custom_apache_ports  => hiera_array('apache_ports', ['0.0.0.0:80']),
    }

    if ! $use_syslog {
      ceph_config {
        'client.radosgw.gateway/log_file':      value => $rgw_log_file;
        'client.radosgw.gateway/log_to_syslog': value => $use_syslog;
      }
    }

    exec { "Create ${rgw_large_pool_name} pool":
      command => "ceph -n client.radosgw.gateway osd pool create ${rgw_large_pool_name} ${rgw_large_pool_pg_nums} ${rgw_large_pool_pg_nums}",
      path    => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin',
      unless  => "rados lspools | grep '^${rgw_large_pool_name}$'",
    }

    Ceph::Key["client.${gateway_name}"] -> Exec["Create ${rgw_large_pool_name} pool"]
  }

}
