class nagios::command inherits nagios::master {
  # Local
  nagios::command::commands { 'check_ntp_time':
    command => '$USER1$/check_ntp_time -H $HOSTADDRESS$',
  }

  if $::osfamily == 'RedHat' {
    nagios::command::commands {
      'check_nrpe':
        command => '/usr/lib64/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$ -a $ARG2$';
      'check_nrpe_1arg':
        command => '/usr/lib64/nagios/plugins/check_nrpe -H $HOSTADDRESS$ -c $ARG1$';
    }
  }

  # Remote

  nagios::command::commands { 'check_http_api':
    command => '$USER1$/check_http -H $HOSTADDRESS$ -p $ARG1$',
  }

  nagios::command::commands { 'check_galera_mysql':
    command => "\$USER1$/check_mysql -H \$HOSTADDRESS$ -P ${nagios::master::mysql_port} -u ${nagios::master::mysql_user} -p ${nagios::master::mysql_pass}",
  }

  nagios::command::commands { 'check_rabbitmq':
    command => "\$USER1$/check_os_rabbitmq connect -H \$HOSTADDRESS$ -P ${nagios::master::rabbit_port} -u ${nagios::master::rabbit_user} -p ${nagios::master::rabbit_pass}",
  }

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
}
