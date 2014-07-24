#
# configures all storage types
# on the same node
#
#  [*storeage_local_net_ip*] ip address that the swift servers should
#    bind to. Required
#  [*devices*] The path where the managed volumes can be found.
#    This assumes that all servers use the same path.
#    Optional. Defaults to /srv/node/
#  [*object_port*] Port where object storage server should be hosted.
#    Optional. Defaults to 6000.
#  [*container_port*] Port where the container storage server should be hosted.
#    Optional. Defaults to 6001.
#  [*account_port*] Port where the account storage server should be hosted.
#    Optional. Defaults to 6002.
#
#
class swift::storage::all(
  $swift_zone,
  $storage_local_net_ip,
  $devices            = '/srv/node',
  $devices_dirs       = undef,
  $object_port        = '6000',
  $container_port     = '6001',
  $account_port       = '6002',
  $object_pipeline    = undef,
  $container_pipeline = undef,
  $account_pipeline   = undef,
  $export_devices     = false,
  $debug              = false,
  $verbose            = true,
) {

  class { 'swift::storage':
    storage_local_net_ip => $storage_local_net_ip,
  }

  if(!defined(File[$devices])) {
    file {$devices:
      ensure       => 'directory',
      owner        => 'swift',
      group        => 'swift',
      recurse      => true,
      recurselimit => 1,
    }
  }

  anchor {'swift-device-directories-start': } -> File[$devices]

  define device_directory($devices){
    if ! defined(File["${devices}/${name}"]){
      file{"${devices}/${name}":
        ensure => 'directory',
        owner => 'swift',
        group => 'swift',
        recurse => true,
        recurselimit => 1,
      }
    }
  }

  if ($devices_dirs != undef){
    device_directory {$devices_dirs :
      devices => $devices,
      require => File[$devices]
    }
  }



  Swift::Storage::Server {
    swift_zone           => $swift_zone,
    devices              => $devices,
    storage_local_net_ip => $storage_local_net_ip,
    debug                => $debug,
    verbose              => $verbose,
  }

  swift::storage::server { $account_port:
    type             => 'account',
    config_file_path => 'account-server.conf',
    pipeline         => $account_pipeline,
  }

  swift::storage::server { $container_port:
    type             => 'container',
    config_file_path => 'container-server.conf',
    pipeline         => $container_pipeline,
  }

  swift::storage::server { $object_port:
    type             => 'object',
    config_file_path => 'object-server.conf',
    pipeline         => $object_pipeline,
  }
}
