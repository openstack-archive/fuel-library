class openstack::swift::storage_node (
  $swift_zone,
  $swift_hash_suffix    = 'swift_secret',
  $swift_local_net_ip   = $::ipaddress_eth0,
  $storage_type         = 'loopback',
  $storage_base_dir     = '/srv/loopback-device',
  $storage_mnt_base_dir = '/srv/node',
  $storage_devices      = ['1', '2'],
  $storage_weight       = 1,
  $package_ensure       = 'present',
  $loopback_size        = '1048756',
  $master_swift_proxy_ip,
  $rings                = ['account', 'object', 'container'],
  $sync_rings           = true,
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

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
    swift_zone           => $swift_zone,
  }

  validate_string($master_swift_proxy_ip)
  
  if $sync_rings {
    if member($rings, 'account') and ! defined(Swift::Ringsync['account']) {
      swift::ringsync { 'account': ring_server => $master_swift_proxy_ip }
    }
  
    if member($rings, 'object') and ! defined(Swift::Ringsync['object']) {
      swift::ringsync { 'object': ring_server => $master_swift_proxy_ip }
    }
  
    if member($rings, 'container') and ! defined(Swift::Ringsync['container']) {
      swift::ringsync { 'container': ring_server => $master_swift_proxy_ip }
    }
    Swift::Ringsync <| |> ~> Class["swift::storage::all"]
  }
  
  
}
