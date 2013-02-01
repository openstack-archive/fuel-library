define nagios::command::commands( $command = false ) {

  @@nagios_command { $name:
    ensure       => present,
    command_line => $command,
    target       => "/etc/${nagios::params::masterdir}/${proj_name}/commands.cfg",
  }
}
