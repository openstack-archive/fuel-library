define nagios::service::services(
$command = false, 
$group = false,
) {

  @@nagios_service { "${::hostname}_${name}":
    ensure              => present,
    use                 => $templateservice,
    hostgroup_name      => $hostgroup,
    check_command       => $command,
    service_description => $name,
    target              => "/etc/nagios3/${proj_name}/${::hostname}_services.cfg",
  }
}
