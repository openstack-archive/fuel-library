class nagios::command {
  # Local
  nagios::command::commands { 'check_ntp_time':
    command => '$USER1$/check_ntp_time -H $HOSTADDRESS$',
  }

  # Remote
  nagios::command::commands { 'nrpe_check_apt':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_apt',
  }

  nagios::command::commands { 'nrpe_check_cert':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_cert -a $ARG1$',
  }

  nagios::command::commands { 'nrpe_check_crm':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_crm',
  }

  nagios::command::commands { 'nrpe_check_disk':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_disk -a $ARG1$ $ARG2$ $ARG3$',
  }

  nagios::command::commands { 'nrpe_check_drbd':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_drbd -a $ARG1$',
  }

  nagios::command::commands { 'nrpe_check_ide_smart':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_ide_smart -a $ARG1$',
  }

  nagios::command::commands { 'nrpe_check_iflocal':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_iflocal -a $ARG1$',
  }

  nagios::command::commands { 'nrpe_check_mailq':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_mailq -a $ARG1$ $ARG2$',
  }

  nagios::command::commands { 'nrpe_check_kernel':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_kernel',
  }

  nagios::command::commands { 'nrpe_check_libs':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_libs',
  }

  nagios::command::commands { 'nrpe_check_load':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_load -a $ARG1$ $ARG2$ $ARG3$ $ARG4$ $ARG5$ $ARG6$',
  }

  nagios::command::commands { 'nrpe_check_procs':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_procs -a $ARG1$ $ARG2$',
  }

  nagios::command::commands { 'nrpe_check_procs_zombie':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_procs_zombie -a $ARG1$ $ARG2$',
  }

  nagios::command::commands { 'nrpe_check_puppet':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_puppet -a $ARG1$ $ARG2$',
  }

  nagios::command::commands { 'nrpe_check_swap':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_swap -a $ARG1$ $ARG2$',
  }

  nagios::command::commands { 'nrpe_check_users':
    command => '$USER1$/check_nrpe -H $HOSTADDRESS$ -c check_users -a $ARG1$ $ARG2$',
  }

  Nagios_command <||> {
    notify  => Exec['fix-permissions'],
    require => File['conf.d'],
  }
}