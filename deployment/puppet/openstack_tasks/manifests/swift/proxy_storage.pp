class openstack_tasks::swift::proxy_storage {

  notice('MODULAR: swift/proxy_storage.pp')

  $network_scheme             = hiera_hash('network_scheme', {})
  $network_metadata           = hiera_hash('network_metadata', {})
  prepare_network_config($network_scheme)

  $swift_hash                 = hiera_hash('swift')
  $swift_master_role          = hiera('swift_master_role', 'primary-controller')
  $swift_nodes                = hiera_hash('swift_nodes', {})
  $swift_operator_roles       = pick($swift_hash['swift_operator_roles'], ['admin', 'SwiftOperator', '_member_'])
  $swift_proxies_addr_list    = values(get_node_to_ipaddr_map_by_network_role(hiera_hash('swift_proxies', {}), 'swift/api'))
  $memcaches_addr_list        = hiera('memcached_addresses')
  $is_primary_swift_proxy     = hiera('is_primary_swift_proxy', false)
  $proxy_port                 = hiera('proxy_port', '8080')
  $storage_hash               = hiera_hash('storage')
  $management_vip             = hiera('management_vip')
  $public_ssl_hash            = hiera_hash('public_ssl')
  $swift_api_ipaddr           = get_network_role_property('swift/api', 'ipaddr')
  $swift_storage_ipaddr       = get_network_role_property('swift/replication', 'ipaddr')
  $debug                      = pick($swift_hash['debug'], hiera('debug', false))
  $verbose                    = pick($swift_hash['verbose'], hiera('verbose', false))
# NOTE(mattymo): Changing ring_part_power or part_hours on redeploy leads to data loss
  $ring_part_power            = pick($swift_hash['ring_part_power'], 10)
  $ring_min_part_hours        = hiera('swift_ring_min_part_hours', 1)
  $deploy_swift_proxy         = hiera('deploy_swift_proxy', true)
  $swift_realm1_key           = hiera('swift_realm1_key', 'realm1key')
#Keystone settings
  $keystone_user              = pick($swift_hash['user'], 'swift')
  $keystone_password          = pick($swift_hash['user_password'], 'passsword')
  $keystone_tenant            = pick($swift_hash['tenant'], 'services')
  $workers_max                = hiera('workers_max', 16)
  $service_workers            = pick($swift_hash['workers'], min(max($::processorcount, 2), $workers_max))
  $ssl_hash                   = hiera_hash('use_ssl', {})
  $rabbit_hash                = hiera_hash('rabbit')
  $rabbit_hosts               = hiera('amqp_hosts')
#storage settings
  $mp_hash                    = hiera('mp')
  $deploy_swift_storage       = hiera('deploy_swift_storage', true)

  $internal_auth_protocol = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', [pick($swift_hash['auth_protocol'], 'http')])
  $internal_auth_address  = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [hiera('service_endpoint', ''), $management_vip])
  $admin_auth_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', [pick($swift_hash['auth_protocol'], 'http')])
  $admin_auth_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [hiera('service_endpoint', ''), $management_vip])

  $auth_uri     = "${internal_auth_protocol}://${internal_auth_address}:5000/"
  $identity_uri = "${admin_auth_protocol}://${admin_auth_address}:35357/"

  $swift_internal_protocol = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'protocol', 'http')
  $swift_internal_address  = get_ssl_property($ssl_hash, {}, 'swift', 'internal', 'hostname', [$swift_api_ipaddr, $management_vip])
  $swift_public_protocol   = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'protocol', 'http')
  $swift_public_address    = get_ssl_property($ssl_hash, $public_ssl_hash, 'swift', 'public', 'hostname', [hiera('swift_endpoint', ''), $public_vip])

  $swift_proxies_num = size(hiera('swift_proxies'))

# Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
    $master_swift_proxy_nodes      = get_nodes_hash_by_roles($network_metadata, [$swift_master_role])
    $master_swift_proxy_nodes_list = values($master_swift_proxy_nodes)
    $master_swift_proxy_ip         = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/api'], '\/\d+$', '')
    $master_swift_replication_ip   = regsubst($master_swift_proxy_nodes_list[0]['network_roles']['swift/replication'], '\/\d+$', '')
    $swift_partition               = hiera('swift_partition', '/var/lib/glance/node')

    if $is_primary_swift_proxy {
      ring_devices {'all':
        storages => $swift_nodes,
        require  => Class['swift'],
      }
    }

    if ($swift_proxies_num < 2) {
      $ring_replicas = 2
    } else {
      $ring_replicas = 3
    }

    if $deploy_swift_proxy {
      class { 'openstack_tasks::swift::parts::proxy':
        swift_user_password            => $swift_hash['user_password'],
        swift_operator_roles           => $swift_operator_roles,
        swift_proxies_cache            => $memcaches_addr_list,
        cache_server_port              => hiera('memcache_server_port', '11211'),
        ring_part_power                => $ring_part_power,
        ring_replicas                  => $ring_replicas,
        primary_proxy                  => $is_primary_swift_proxy,
        swift_proxy_local_ipaddr       => $swift_api_ipaddr,
        swift_replication_local_ipaddr => $swift_storage_ipaddr,
        master_swift_proxy_ip          => $master_swift_proxy_ip,
        master_swift_replication_ip    => $master_swift_replication_ip,
        proxy_port                     => $proxy_port,
        proxy_workers                  => $service_workers,
        debug                          => $debug,
        verbose                        => $verbose,
        log_facility                   => 'LOG_SYSLOG',
        ceilometer                     => hiera('use_ceilometer',false),
        ring_min_part_hours            => $ring_min_part_hours,
        admin_user                     => $keystone_user,
        admin_tenant_name              => $keystone_tenant,
        admin_password                 => $keystone_password,
        auth_host                      => $internal_auth_address,
        auth_protocol                  => $internal_auth_protocol,
        auth_uri                       => $auth_uri,
        identity_uri                   => $identity_uri,
        rabbit_user                    => $rabbit_hash['user'],
        rabbit_password                => $rabbit_hash['password'],
        rabbit_hosts                   => split($rabbit_hosts, ', '),
      }

      # Check swift proxy and internal VIP are from the same IP network. If no
      # then it's possible to get network failure, so proxy couldn't access
      # Keystone via VIP. In such cases swift health check returns OK, but all
      # requests forwarded from HAproxy fail, see LP#1459772 In order to detect
      # such bad swift backends we enable a service which checks Keystone
      # availability from swift node. HAProxy monitors that service to get
      # proper backend status.
      # NOTE: this is the same logic in the HAproxy configuration so if it's
      # updated there, this must be updated. See LP#1548275
      $swift_api_network = get_network_role_property('swift/api', 'network')
      $bind_to_one       = has_ip_in_network($management_vip, $swift_api_network)

      if !$bind_to_one {
        $storage_nets = get_routable_networks_for_network_role($network_scheme, 'swift/replication', ' ')
        $mgmt_nets = get_routable_networks_for_network_role($network_scheme, 'swift/api', ' ')

        class { 'openstack_tasks::swift::parts::status':
          endpoint    => "${swift_internal_protocol}://${swift_internal_address}:${proxy_port}",
          scan_target => "${internal_auth_address}:5000",
          only_from   => "127.0.0.1 240.0.0.2 ${storage_nets} ${mgmt_nets}",
          con_timeout => 5
        }

        Class['openstack_tasks::swift::parts::status'] -> Class['swift::dispersion']
      }

      class { 'swift::dispersion':
        auth_url       => "${internal_auth_protocol}://${internal_auth_address}:5000/v2.0/",
        auth_user      =>  $keystone_user,
        auth_tenant    =>  $keystone_tenant,
        auth_pass      =>  $keystone_password,
        auth_version   =>  '2.0',
      }

      Class['openstack_tasks::swift::parts::proxy'] -> Class['swift::dispersion']
      Service<| tag == 'swift-service' |> -> Class['swift::dispersion']
    }

    if $deploy_swift_storage {
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

      class { 'openstack_tasks::swift::parts::storage_node':
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

    # swift_container_sync_realms file specifying
    # the allowable clusters and their information.
    # Changes in this file don't require restart services.
    # This config should be present on proxy and containers nodes.
    if $deploy_swift_storage or $deploy_swift_proxy {
      swift_container_sync_realms_config {
        'realm1/key':           value => $swift_realm1key;
        'realm1/cluster_name1': value => "${swift_public_protocol}://${swift_public_address}:8080/v1";
      }
    }

  }
}
