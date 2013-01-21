define nagios::command::commands($command = false) {
  nagios_command { $name:
    ensure       => present,
    command_line => $command,
    target       => '/etc/nagios3/conf.d/commands.cfg',
  }
}