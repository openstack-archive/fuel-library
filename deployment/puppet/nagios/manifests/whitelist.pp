define nagios::whitelist($whitelist = false) {
  $t_whitelist = $whitelist ? {
    false   => '127.0.0.1',
    default => $whitelist,
  }

  file { $name:
    owner   => root,
    group   => root,
    mode    => '0644',
    alias   => 'nrpe.cfg',
    notify  => Service['nagios-nrpe-server'],
    content => template('nagios/common/etc/nagios/nrpe.cfg.erb'),
    require => Package['nagios-nrpe-server'],
  }
}
