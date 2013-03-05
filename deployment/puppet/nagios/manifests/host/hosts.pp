define nagios::host::hosts() {

  @@nagios_host { $name:
    ensure     => present,
#    hostgroups => $hostgroup,
    alias      => $::hostname,
    use        => 'default-host',
    address    => $::fqdn,
    host_name  => $::fqdn,
    target     => "/etc/${nagios::params::masterdir}/${nagios::master_proj_name}/${::hostname}_hosts.cfg",
  }
}
