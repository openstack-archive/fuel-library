define nagios::host::hosts() {
  @@nagios_host { $name:
    ensure     => present,
    alias      => $::hostname,
    address    => $::ipaddress,
    hostgroups => $::lsbdistcodename,
    use        => 'generic-host',
    target     => "/etc/nagios3/conf.d/${::hostname}_hosts.cfg",
  }
}