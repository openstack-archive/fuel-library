class lvm(
  $ensure = 'present',
  $vg = 'volume-group-00',
  $pv = undef,
) {

  if ! $pv {
    fail('The pv(physical volume) parameter is not defined')
  }

  package{ 'lvm2':
    ensure => $ensure,
  }

  physical_volume { $pv:
    ensure  => $ensure,
    require => Package['lvm2'],
  }

  volume_group { $vg:
    ensure           => $ensure,
    physical_volumes => $pv,
    require          => Physical_volume[$pv]
  }

}
