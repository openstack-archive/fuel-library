define nagios::command::commands( $command = false ) {

  nagios_command { $name:
    ensure       => present,
    command_line => $command,
    target       => "/etc/${nagios::params::masterdir}/${nagios::master::master_proj_name}/commands.cfg",
    notify       => Exec['fix-permissions'],
    require      => File['conf.d'],
  }
}
