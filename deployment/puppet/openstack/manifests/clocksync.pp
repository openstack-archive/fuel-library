class openstack::clocksync ($ntp_servers = undef, $config_template = undef)
{

  if !$ntp_servers {
    $one_shot_ntp_server = 'pool.ntp.org'
  } else {
    $one_shot_ntp_server = $ntp_servers[0]
  }
  class { 'ntp': 
    servers         => $ntp_servers, 
    config_template => $config_template
  }

  Exec['clocksync'] -> Service <| title == 'ntp' |>

  package {'ntpdate': ensure => present}

  exec {'clocksync':
    unless  => "pidof ntpd",
    require => Package['ntpdate'],
    command => "bash -c 'for i in {1..10}; do ntpdate $one_shot_ntp_server &&  break; sleep 1; done'",
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
  }
}


