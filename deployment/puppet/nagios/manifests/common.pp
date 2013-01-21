class nagios::common {
  nagios::host::hosts { $::hostname: }

  nagios::host::hostextinfo { $::hostname: }

  if $::virtual == 'physical' {
    $a_disks = split($::disks, ',')
    nagios::service::services { $a_disks:
      command => 'nrpe_check_ide_smart!/dev/',
      group   => 'smart',
    }

    $a_interfaces = split($::interfaces, ',')
    nagios::service::services { $a_interfaces:
      command => 'nrpe_check_iflocal!',
      group   => 'interfaces',
    }
  }

  nagios::service::services { 'apt':
    command => 'nrpe_check_apt',
  }

  $a_mountpoints = split($::mountpoints, ',')
  nagios::service::services { $a_mountpoints:
    command => 'nrpe_check_disk!25%!10%!',
    group   => 'disks',
  }

  nagios::service::services { 'kernel':
    command => 'nrpe_check_kernel',
  }

  nagios::service::services { 'libs':
    command => 'nrpe_check_libs',
  }

  nagios::service::services { 'load':
    command => 'nrpe_check_load!5.0!4.0!3.0!10.0!6.0!4.0',
  }

  nagios::service::services { 'procs':
    command => 'nrpe_check_procs!250!400',
  }

  nagios::service::services { 'zombie':
    command => 'nrpe_check_procs_zombie!5!10',
    group   => 'procs',
  }

  nagios::service::services { 'swap':
    command => 'nrpe_check_swap!20%!10%',
  }

  nagios::service::services { 'user':
    command => 'nrpe_check_users!5!10',
  }
}