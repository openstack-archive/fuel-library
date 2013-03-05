define nagios::service::services(
$command = false,
$group   = false,
) {

  @@nagios_service { "${::hostname}_${name}":
    ensure              => present,
    hostgroup_name      => $nagios::hostgroup,
    check_command       => $command,
    service_description => $name,
    host_name           => $::fqdn,
    target              => "/etc/${nagios::params::masterdir}/${nagios::master_proj_name}/${::hostname}_services.cfg",
  }
}
