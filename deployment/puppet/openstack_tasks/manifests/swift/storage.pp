class openstack_tasks::swift::storage {
  notice('MODULAR: swift/storage.pp')

  $network_scheme             = hiera_hash('network_scheme', {})
  $network_metadata           = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $swift_hash                 = hiera_hash('swift')
  $swift_master_role          = hiera('swift_master_role', 'primary-controller')
  $is_primary_swift_proxy     = hiera('is_primary_swift_proxy', false)
  $proxy_port                 = hiera('proxy_port', '8080')
  $storage_hash               = hiera_hash('storage')
  $mp_hash                    = hiera('mp')
  $swift_storage_ipaddr       = get_network_role_property('swift/replication', 'ipaddr')
  $debug                      = pick($swift_hash['debug'], hiera('debug', false))
  $verbose                    = pick($swift_hash['verbose'], hiera('verbose', false))
  $deploy_swift_storage       = hiera('deploy_swift_storage', true)

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
    $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
    $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
    $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
    $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')
    $swift_partition               = hiera('swift_partition', '/var/lib/glance/node')

    if ($deploy_swift_storage) {
      if !defined(File['/var/lib/glance']) {
        file {'/var/lib/glance':
          ensure  => 'directory',
          group   => 'swift',
          require => Package['swift'],
        } -> Service <| tag == 'swift-service' |>
      } else {
        File['/var/lib/glance'] {
          ensure  => 'directory',
          group   => 'swift',
          require +> Package['swift'],
        }
        File['/var/lib/glance'] -> Service <| tag == 'swift-service' |>
      }

      class { '::openstack_tasks::swift::parts::storage_node':
        storage_type                => false,
        loopback_size               => '5243780',
        storage_mnt_base_dir        => $swift_partition,
        storage_devices             => filter_hash($mp_hash,'point'),
        swift_zone                  => $master_swift_proxy_nodes_list[0]['swift_zone'],
        swift_local_net_ip          => $swift_storage_ipaddr,
        master_swift_proxy_ip       => $master_swift_proxy_ip,
        master_swift_replication_ip => $master_swift_replication_ip,
        sync_rings                  => ! $is_primary_swift_proxy,
        debug                       => $debug,
        verbose                     => $verbose,
        log_facility                => 'LOG_SYSLOG',
      }
    }

  }

}
