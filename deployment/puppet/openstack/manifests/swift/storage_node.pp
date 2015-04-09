#
class openstack::swift::storage_node (
  $swift_zone,
  $swift_hash_suffix          = 'swift_secret',
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
  $rings                      = [
    'account',
    'object',
    'container'],
  $sync_rings                 = true,
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
  ) {
  if !defined(Class['swift']) {
    class { 'swift':
      swift_hash_suffix => $swift_hash_suffix,
      package_ensure    => $package_ensure,
    }
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

  # create dirs for devices
  define device_directory($devices) {
    if(!defined(File[$devices])) {
      file { $devices:
        ensure       => 'directory',
        owner        => 'swift',
        group        => 'swift',
        recurse      => true,
        recurselimit => 1,
      }
    }
  }
  if ($storage_devices != undef) {
    anchor {'swift-device-directories-start': } ->
    device_directory { $storage_devices:
      devices => $storage_mnt_base_dir,
    }
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
    devices              => $storage_mnt_base_dir,
    log_facility         => $log_facility,
  }
  # override log_name defaults for Swift::Storage::Server
  # TODO (adidenko) move this into Hiera when it's ready
  Swift::Storage::Server <| title == '6000' |> {
    log_name => 'swift-object-server',
  }
  Swift::Storage::Server <| title == '6001' |> {
    log_name       => 'swift-container-server',
    allow_versions => true,
  }
  Swift::Storage::Server <| title == '6002' |> {
    log_name => 'swift-account-server',
  }

  validate_string($master_swift_proxy_ip)

  if $sync_rings {
    if member($rings, 'account') and !defined(Swift::Ringsync['account']) {
      swift::ringsync { 'account': ring_server => $master_swift_proxy_ip }
    }

    if member($rings, 'object') and !defined(Swift::Ringsync['object']) {
      swift::ringsync { 'object': ring_server => $master_swift_proxy_ip }
    }

    if member($rings, 'container') and !defined(Swift::Ringsync['container']) {
      swift::ringsync { 'container': ring_server => $master_swift_proxy_ip }
    }
    Swift::Ringsync <| |> ~> Class["swift::storage::all"]
  }

}

