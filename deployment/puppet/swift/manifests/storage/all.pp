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
#  [*allow_versions*] Boolean to enable the versioning in swift container
#    Optional. Default to false.
#  [*container_port*] Port where the container storage server should be hosted.
#    Optional. Defaults to 6001.
#  [*account_port*] Port where the account storage server should be hosted.
#    Optional. Defaults to 6002.
#
#
class swift::storage::all(
  $storage_local_net_ip,
  $devices            = '/srv/node',
  $object_port        = '6000',
  $container_port     = '6001',
  $account_port       = '6002',
  $object_pipeline    = undef,
  $container_pipeline = undef,
  $allow_versions     = false,
  $mount_check        = false,
  $account_pipeline   = undef,
  $log_facility       = 'LOG_LOCAL2'
) {

  class { 'swift::storage':
    storage_local_net_ip => $storage_local_net_ip,
  }

  Swift::Storage::Server {
    devices              => $devices,
    storage_local_net_ip => $storage_local_net_ip,
    mount_check          => $mount_check,
  }

  swift::storage::server { $account_port:
    type             => 'account',
    config_file_path => 'account-server.conf',
    pipeline         => $account_pipeline,
    log_facility     => $log_facility,
  }

  swift::storage::server { $container_port:
    type             => 'container',
    config_file_path => 'container-server.conf',
    pipeline         => $container_pipeline,
    log_facility     => $log_facility,
    allow_versions   => $allow_versions,
  }

  swift::storage::server { $object_port:
    type             => 'object',
    config_file_path => 'object-server.conf',
    pipeline         => $object_pipeline,
    log_facility     => $log_facility,
  }
}
