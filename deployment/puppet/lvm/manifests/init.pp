class lvm(
  $ensure = 'present',
  $vg = 'volume-group-00',
  $pv = undef
) {

  if ! $pv {
    warning('The pv(physical volume) parameter is not defined. The loopback device will be created automatically')

    $pv_name = '/dev/loop2'
    class { 'lvm::create_loopback':
      loopback_device => $pv_name,
      require => Package['lvm2'],
    }
  } else {
    $pv_name = $pv
  }

  package { 'lvm2':
    ensure => $ensure,
  }

  physical_volume { $pv_name:
    ensure  => $ensure,
    require => Package['lvm2'],
  }

  volume_group { $vg:
    ensure           => $ensure,
    physical_volumes => $pv_name,
    require          => Physical_volume[$pv_name]
  }

}
