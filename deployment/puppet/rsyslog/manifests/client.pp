class rsyslog::client (
  $log_remote     = true,
  $remote_type    = 'tcp',
  $log_local      = false,
  $log_auth_local = false,
  $custom_config  = undef,
  $server         = 'log',
  $port           = '514',
  $escapenewline  = false,
  $rservers       = undef
  ) inherits rsyslog {

  if $rservers == undef {
    $rservers = [{'remote_type'=>$remote_type, 'server'=>$server, 'port'=>$port}]
  }

  $content_real = $custom_config ? {
    ''      => template("${module_name}/client.conf.erb"),
    default => template($custom_config),
  }

  file { $rsyslog::params::client_conf:
    ensure  => present,
    owner   => root,
    group   => $rsyslog::params::run_group,
    content => $content_real,
    require => Class['rsyslog::config'],
    notify  => Class['rsyslog::service'],
  }
}
