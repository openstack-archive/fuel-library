#
#
#

class rsyslog::client (
  $log_remote     = true,
  $remote_type    = 'udp',
  $log_local      = true,
  $log_auth_local = true,
  $custom_config  = undef,
  $server         = 'master',
  $port           = '514',
  $escapenewline  = false,
  $rservers       = undef
  ) inherits rsyslog {

  include rsyslog::checksum_udp514

  if $rservers == undef {
    $rservers_real = [{'remote_type'=>$remote_type, 'server'=>$server, 'port'=>$port}]
  }
  else {
    $rservers_real = $rservers
  }

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

  file { "${rsyslog::params::rsyslog_d}60-puppet-agent.conf":
    content => template("${module_name}/60-puppet-agent.conf.erb"),

  }

  file { "${rsyslog::params::rsyslog_d}90-local.conf":
    content => template("${module_name}/90-local.conf.erb"),

  }

  file { "${rsyslog::params::rsyslog_d}99-remote.conf":
    content => template("${module_name}/99-remote.conf.erb"),

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
