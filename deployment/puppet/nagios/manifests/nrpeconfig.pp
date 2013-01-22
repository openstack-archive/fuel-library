define nagios::nrpeconfig(
$whitelist   = '127.0.0.1',
$include_dir = '/etc/nagios/nrpe.d',
){

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
