# Class for rsyslog server/client logging
# (assumes package rsyslog were installed at BM)
#
# [role] log server or client
# [log_remote] send logs to remote server(s). Can be used with local logging.
# [log_local], [log_auth_local] local & auth logging. Can be used with remote logging.
# [syslog_log_facility_XXX] syslog (client role only) facility for service XXX.
# [rotation] logrotate option for rotation period - daily, weekly, monthly, yearly.
# [keep] logrotate option for number or rotated log files to keep.
# [limitsize] logrotate option for log files would be rotated, if exceeded.
# [rservers] array of hashes which represents remote logging servers for client role.
# [port] port to use by server role for remote logging.
# [proto] tcp/udp proto for remote log server role.
# [show_timezone] if enabled, high_precision_timestamps (date-rfc3339) with GMT would be used
#   for logging. Default is false (date-rfc3164), examples:
#     date-rfc3339: 2010-12-05T02:21:41.889482+01:00,
#     date-rfc3164: Dec 5 02:21:13,
# [virtual] if node is virtual, fix for udp checksums should be applied
# [rabbit_log_level] should be >= global syslog_log_level option,
#   otherwise none messages would have gone to syslog (client role only)
# [debug] switch between debug and standard cases, client role only. imfile monitors for local logs would be used if debug.

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
    $syslog_log_facility_glance   = 'LOCAL2',
    $syslog_log_facility_cinder   = 'LOCAL3',
    $syslog_log_facility_quantum  = 'LOCAL4',
    $syslog_log_facility_nova     = 'LOCAL6',
    $syslog_log_facility_keystone = 'LOCAL7',
    $rabbit_log_level = 'NOTICE',
    $debug          = false,
) {

validate_re($proto, 'tcp|udp')
validate_re($role, 'client|server')
validate_re($rotation, 'daily|weekly|monthly|yearly')

if $role == 'client' {
  class { "::rsyslog::client":
    high_precision_timestamps => $show_timezone,
    log_remote     => $log_remote,
    log_local      => $log_local,
    log_auth_local => $log_auth_local,
    rservers       => $rservers,
    virtual        => $virtual,
    syslog_log_facility_glance => $syslog_log_facility_glance,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_facility_nova => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    log_level      => $rabbit_log_level,
    debug          => $debug,
  }

} else { # server
  firewall { "$port $proto rsyslog":
    port    => $port,
    proto   => $proto,
    action  => 'accept',
  } # ->
# FIXME unless firewall module rule parser's idempotency would have been fixed,
# do not add firewall to dependency chains cuz it would broke it on reapply.
# If we want to change logging settings at server node, we would have to reappy
# this class with new settings provided, ignoring firewall module's broken
# idempotency as well...
  class {"::rsyslog::server":
    enable_tcp => $proto ? { 'tcp' => true, default => false },
    enable_udp => $proto ? { 'udp' => true, default => true },
    server_dir => '/var/log/',
    port       => $port,
    high_precision_timestamps => $show_timezone,
    virtual    => $virtual,
  }
}

  class {"::openstack::logrotate":
    rotation       => $rotation,
    keep           => $keep,
    limitsize      => $limitsize,
  }
}
