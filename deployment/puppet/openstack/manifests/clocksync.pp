class openstack::clocksync ($ntp_servers = undef, $config_template = undef)
{

  if !$ntp_servers {
    $one_shot_ntp_server = 'pool.ntp.org'
  } else {
    $one_shot_ntp_server = $ntp_servers[0]
  }
  class { 'ntp':
    servers         => $ntp_servers,
    config_template => $config_template,
    disable_monitor => true,
    iburst_enable   => true,
    udlc            => !check_ntp($one_shot_ntp_server),
    tinker          => true,
    panic           => 0,
    stepout         => 5,
    minpoll         => 3,
    maxpoll         => 9,
  }

  Exec['clocksync'] -> Service <| title == 'ntp' |>

  package {'ntpdate': ensure => present}

  exec {'clocksync':
    unless  => "pidof ntpd",
    require => Package['ntpdate'],
    command => "bash -c 'for i in {1..10}; do ntpdate -p 4 -t 0.2 -ub $one_shot_ntp_server &&  break; sleep 1; done'",
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
  }
}


