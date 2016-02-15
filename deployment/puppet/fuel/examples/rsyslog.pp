notice('MODULAR: rsyslog.pp')

Class['rsyslog::server'] ->
Class['openstack::logrotate']

class {'::rsyslog::server':
  enable_tcp                => true,
  enable_udp                => true,
  server_dir                => '/var/log/',
  port                      => 514,
  high_precision_timestamps => true,
}

# Fuel specific config for logging parse formats used for /var/log/remote
$show_timezone = true
$logconf = "${::rsyslog::params::rsyslog_d}30-remote-log.conf"
file { $logconf :
    content => template('openstack/30-server-remote-log.conf.erb'),
    require => Class['::rsyslog::server'],
    owner   => root,
    group   => $::rsyslog::params::run_group,
    mode    => '0640',
    notify  => Class['::rsyslog::service'],
}

class { '::openstack::logrotate':
  role     => 'server',
  rotation => 'weekly',
  keep     => '4',
  minsize  => '10M',
  maxsize  => '20M',
}

fuel::systemd {'rsyslog':
  start         => true,
  template_path => 'fuel/systemd/restart_template.erb',
  config_name   => 'restart.conf',
  require       => Class['::rsyslog::server'],
}
