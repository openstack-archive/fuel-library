# Class for rsyslog server/client logging
#
# [role] log server or client
# [log_remote] send logs to remote server(s). Can be used with local logging.
# [log_local], [log_auth_local] local & auth logging. Can be used with remote logging.
# [rotation] logrotate option for rotation period - daily, weekly, monthly, yearly.
# [keep] logrotate option for number or rotated log files to keep.
# [limitsize] logrotate option for log files would be rotated, if exceeded.
# [rservers] array of hashes which represents remote logging servers for client role.
# [port] port to use by server role for remote logging.
# [proto] tcp/udp proto for remote log server role.
# [show_timezone] if enabled, high_precision_timestamps with GMT would be used for server role. 
# [virtual] if node is virtual, fix for udp checksums should be applied

class openstack::logging (
    $role           = 'client',
    $log_remote     = true,
    $log_local      = false,
    $log_auth_local = false,
    $rotation       = 'daily',
    $keep           = '7',
    $limitsize      = '300M',
    $rservers       = [{'remote_type'=>'udp', 'server'=>'master', 'port'=>'514'},],
    $port           = '514',
    $proto          = 'udp',
    $show_timezone  = false,
    $virtual        = false,
) {

validate_re($proto, 'tcp|udp')
validate_re($role, 'client|server')
validate_re($rotation, 'daily|weekly|monthly|yearly')

if $role == 'client' {
  class { "::rsyslog::client":
    log_remote     => $log_remote,
    log_local      => $log_local,
    log_auth_local => $log_auth_local,
    rservers       => $rservers,
    virtual        => $virtual,
  } ->
# FIXME Find more appropriate way to ensure rsyslog service would be restarted
# while custom runstage openstack::logging class has been called within
  exec {'rsyslog_forcerestart':
    path    => ["/usr/bin", "/usr/sbin", "/sbin", "/bin"],
    command => "service ${::rsyslog::params::service_name} restart",
    returns => 0,
  }

} else { # server
  firewall { "$port $proto rsyslog":
    port    => $port,
    proto   => $proto,
    action  => 'accept',
  } ->
  class {"::rsyslog::server": 
    enable_tcp => $proto == 'tcp' ? { true => 'true', default =>'false' },
    enable_udp => $proto == 'udp' ? { true => 'true', default =>'true' },
    server_dir => '/var/log/',
    high_precision_timestamps => $show_timezone,
    virtual    => $virtual,
  } -> 
# FIXME Find more appropriate way to ensure rsyslog service would be restarted
# while custom runstage openstack::logging class has been called within
  exec {'rsyslog_forcerestart':
    path    => ["/usr/bin", "/usr/sbin", "/sbin", "/bin"],
    command => "service ${::rsyslog::params::service_name} restart",
    returns => 0,
  }
}

  class {"::openstack::logrotate": 
    rotation       => $rotation,
    keep           => $keep,
    limitsize      => $limitsize,
  }
}
