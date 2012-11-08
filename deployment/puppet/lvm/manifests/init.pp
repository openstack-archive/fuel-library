class lvm(
  $loopfile = undef,
  $ensure = 'present',
  $vg = 'volume-group-00',
  $pv = undef,
) {

    if ! $pv and ! $loopfile {
      fail('The pv (physical volume) or loopfile parameter is not defined')
    }

  package{ 'lvm2':
    ensure => $ensure,
  }

  if  $pv {
  
    physical_volume { $pv: 
      ensure => $ensure,
      require => Package['lvm2'],
    }
  
    volume_group { $vg:
      ensure           => $ensure,
      physical_volumes => $pv,
      require          => Physical_volume[$pv],
    }
  }

  else {

    exec { 'volumes':
      command => "/bin/dd if=/dev/zero of=${loopfile} bs=2M seek=20k count=0 && /sbin/vgcreate ${vg} `/sbin/losetup --show -f ${loopfile}`",
      creates => "${loopfile}",
      require => Package['lvm2'],
    }
  }

}
