#
#
#

class rsyslog::client (
  $log_remote     = true,
  $remote_type    = 'tcp',
  $log_local      = false,
  $log_auth_local = false,
  $custom_config  = undef,
  $server         = 'log',
  $escapenewline  = false,
  ) inherits rsyslog {

  $content_real = $custom_config ? {
    ''      => template("${module_name}/01-client.conf.erb"),
    default => template($custom_config),
  }

  File {
    owner => root,
    group => $rsyslog::params::run_group,
    mode => 0640,
    notify  => Class["rsyslog::service"],
  }

  file { $rsyslog::params::rsyslog_d:
    purge   => true,
    recurse => true,
    force   => true,
    ensure  => directory,
  }

  file { $rsyslog::params::client_conf:
    ensure  => present,
    content => $content_real,
    require => File[$rsyslog::params::rsyslog_d],
  }
}
