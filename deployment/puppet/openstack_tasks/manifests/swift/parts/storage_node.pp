class openstack_tasks::swift::parts::storage_node (
  $swift_zone,
  $swift_hash_suffix          = 'swift_secret',
  $swift_max_header_size      = '32768',
  $swift_local_net_ip         = $::ipaddress_eth0,
  $storage_type               = 'loopback',
  $storage_base_dir           = '/srv/loopback-device',
  $storage_mnt_base_dir       = '/srv/node',
  $storage_devices            = [
    '1',
    '2'],
  $storage_weight             = 1,
  $package_ensure             = 'present',
  $loopback_size              = '1048756',
  $master_swift_proxy_ip,
  $master_swift_replication_ip,
  $rings                      = [
    'account',
    'object',
    'container'],
  $sync_rings                 = true,
  $incoming_chmod             = 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  $outgoing_chmod             = 'Du=rwx,g=rx,o=rx,Fu=rw,g=r,o=r',
  # if the cinder management components should be installed
  $cinder                     = true,
  $manage_volumes             = false,
  $nv_physical_volume         = undef,
  $cinder_volume_group        = 'cinder-volumes',
  $cinder_user_password       = 'cinder_user_pass',
  $cinder_db_password         = 'cinder_db_pass',
  $cinder_db_user             = 'cinder',
  $cinder_db_dbname           = 'cinder',
  $cinder_iscsi_bind_addr     = false,
  $cinder_rate_limits         = false,
  $db_host                    = '127.0.0.1',
  $service_endpoint           = '127.0.0.1',
  $use_syslog                 = false,
  $syslog_log_facility_cinder = 'LOG_LOCAL3',
  $debug                      = false,
  $verbose                    = true,
  # Rabbit details necessary for cinder
  $rabbit_nodes               = false,
  $rabbit_password            = 'rabbit_pw',
  $rabbit_host                = false,
  $rabbit_user                = 'nova',
  $rabbit_ha_virtual_ip       = false,
  $queue_provider             = 'rabbitmq',
  $qpid_password              = 'qpid_pw',
  $qpid_user                  = 'nova',
  $qpid_nodes                 = ['127.0.0.1'],
  $log_facility               = 'LOG_LOCAL2',
  $rsync_group                = 'glance',
) {
  if !defined(Class['swift']) {
    class { 'swift':
      swift_hash_path_suffix => $swift_hash_suffix,
      package_ensure         => $package_ensure,
      max_header_size        => $swift_max_header_size,
    }
  }

  swift::storage::filter::recon {'object':
    require => Class[swift],
  }

  if $storage_type == 'loopback' {
    # create xfs partitions on a loopback device and mount them
    swift::storage::loopback { $storage_devices:
      base_dir     => $storage_base_dir,
      mnt_base_dir => $storage_mnt_base_dir,
      seek         => $loopback_size,
      require      => Class['swift'],
    }
  }

  if $storage_devices != undef {
    anchor {'swift-device-directories-start': } ->
    openstack_tasks::swift::parts::device_directory { $storage_devices:
      devices => $storage_mnt_base_dir,
    }
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
    devices              => $storage_mnt_base_dir,
    log_facility         => $log_facility,
    # We use directory for swift
    mount_check          => false,
  }
  # override log_name defaults for Swift::Storage::Server
  # TODO (adidenko) move this into Hiera when it's ready
  Swift::Storage::Server <| title == '6000' |> {
    group    => $rsync_group,
    log_name => 'swift-object-server',
  }
  Swift::Storage::Server <| title == '6001' |> {
    group          => $rsync_group,
    log_name       => 'swift-container-server',
    allow_versions => true,
  }
  Swift::Storage::Server <| title == '6002' |> {
    group    => $rsync_group,
    log_name => 'swift-account-server',
  }
  Swift::Storage::Server <| |> {
    incoming_chmod => $incoming_chmod,
    outgoing_chmod => $outgoing_chmod,
  }

  validate_string($master_swift_replication_ip)

  if $sync_rings {
    if member($rings, 'account') and !defined(Swift::Ringsync['account']) {
      swift::ringsync { 'account': ring_server => $master_swift_replication_ip }
    }

    if member($rings, 'object') and !defined(Swift::Ringsync['object']) {
      swift::ringsync { 'object': ring_server => $master_swift_replication_ip }
    }

    if member($rings, 'container') and !defined(Swift::Ringsync['container']) {
      swift::ringsync { 'container': ring_server => $master_swift_replication_ip }
    }
    Swift::Ringsync <| |> ~> Class["swift::storage::all"]
  }
}
