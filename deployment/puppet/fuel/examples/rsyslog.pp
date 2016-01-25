notice('MODULAR: rsyslog.pp')

Class['rsyslog::server'] ->
Class['openstack::logrotate']

include ::rsyslog::params

# We do not supply these packages for our fuel master so we need to set them
# to false so the module does not attempt to install it.
class { '::rsyslog':
  relp_package_name   => false,
  gnutls_package_name => false,
  mysql_package_name  => false,
  pgsql_package_name  => false,
}

class { '::rsyslog::server':
  enable_tcp                => true,
  enable_udp                => true,
  enable_relp               => false,
  server_dir                => '/var/log/',
  port                      => 514,
  high_precision_timestamps => true,
}

::rsyslog::snippet{ '00-disable-EscapeControlCharactersOnReceive':
  content => '$EscapeControlCharactersOnReceive off'
}

# Fuel specific config for logging parse formats used for /var/log/remote
$show_timezone = true
::rsyslog::snippet { '30-remote-log':
  content => template('openstack/30-server-remote-log.conf.erb'),
}

Rsyslog::Snippet <| |> -> Service["$::rsyslog::params::service_name"]

fuel::systemd {'rsyslog':
  start         => true,
  template_path => 'fuel/systemd/restart_template.erb',
  config_name   => 'restart.conf',
  require       => Class["::rsyslog::server"],
}

class { '::openstack::logrotate':
  role     => 'server',
  rotation => 'weekly',
  keep     => '4',
  minsize  => '10M',
  maxsize  => '20M',
}
