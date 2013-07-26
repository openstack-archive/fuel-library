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
# [proto] tcp/udp/both proto(s) for remote log server role.
# [show_timezone] if enabled, high_precision_timestamps (date-rfc3339) with GMT would be used
#   for logging. Default is false (date-rfc3164), examples:
#     date-rfc3339: 2010-12-05T02:21:41.889482+01:00,
#     date-rfc3164: Dec 5 02:21:13,
# [virtual] if node is virtual, fix for udp checksums should be applied
# [rabbit_log_level] should be >= global syslog_log_level option,
#   otherwise none messages would have gone to syslog (client role only).
# [logstash_node|_port] node and port for logstash server. Both for client and server roles
# [elasticsearch_node] node for elasticsearch service (port is 9200). For server role only.
# [kibana_host|_port] node and port for kibana WEB UI. Both for client and server roles.
# [cluster_name] name for logstash cluster

class openstack::logging (
    $role           = 'client',
    $log_remote     = true,
    $log_local      = false,
    $log_auth_local = false,
    $rotation       = 'daily',
    $keep           = '7',
    $limitsize      = '300M',
    $rservers       = [{'remote_type'=>'udp', 'server'=>'fuel', 'port'=>'514'},],
    $port           = '514',
    $proto          = 'udp',
    $show_timezone  = false,
    $virtual        = false,
    $syslog_log_facility_murano   = 'LOG_LOCAL0',
    $syslog_log_facility_glance   = 'LOG_LOCAL2',
    $syslog_log_facility_cinder   = 'LOG_LOCAL3',
    $syslog_log_facility_neutron  = 'LOG_LOCAL4',
    $syslog_log_facility_nova     = 'LOG_LOCAL6',
    $syslog_log_facility_keystone = 'LOG_LOCAL7',
    $syslog_log_facility_heat     = 'LOG_LOCAL0',
    $syslog_log_facility_savanna  = 'LOG_LOCAL0',
    $rabbit_log_level = 'NOTICE',
    $debug          = false,
    $logstash_node = 'fuel',
    $logstash_port = '55514',
    $elasticsearch_node = 'localhost',
    $kibana_host = '0.0.0.0',
    $kibana_port = '5601',
    $cluster_name = 'fuel_001',
) {

validate_re($proto, 'tcp|udp|both')
validate_re($role, 'client|server')
validate_re($rotation, 'daily|weekly|monthly|yearly')

if $role == 'client' {
  # Configure clients to send remote logs to rsyslog and Logstash
  class { "::rsyslog::client":
    high_precision_timestamps => $show_timezone,
    log_remote     => $log_remote,
    log_local      => $log_local,
    log_auth_local => $log_auth_local,
    rservers       => $rservers,
    virtual        => $virtual,
    syslog_log_facility_glance => $syslog_log_facility_glance,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    syslog_log_facility_neutron  => $syslog_log_facility_neutron,
    syslog_log_facility_nova => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    syslog_log_facility_heat     => $syslog_log_facility_heat,
    syslog_log_facility_savanna  => $syslog_log_facility_savanna,
    log_level      => $rabbit_log_level,
    debug          => $debug,
    logstash_node  => $logstash_node,
    logstash_port  => $logstash_port,
    proto          => $proto,
  }

} else { # server

if $proto == 'both' {
  firewall { "$port udp rsyslog":
    port    => $port,
    proto   => 'udp',
    action  => 'accept',
  }
  firewall { "$port tcp rsyslog":
    port    => $port,
    proto   => 'tcp',
    action  => 'accept',
  }
} else {
  firewall { "$port $proto rsyslog":
    port    => $port,
    proto   => $proto,
    action  => 'accept',
  }
}
  class {"::rsyslog::server":
    enable_tcp => $proto ? { 'tcp' => true, 'both' => true, default => false },
    enable_udp => $proto ? { 'udp' => true, 'both' => true, default => true },
    server_dir => '/var/log/',
    port       => $port,
    high_precision_timestamps => $show_timezone,
    virtual    => $virtual,
  }

  # Rules for logstash, need both tcp&udp
  firewall { "9200, 9300-9400, ${kibana_port} tcp kibana-elasticsearch":
    port    => [ $kibana_port, '9200', '9300-9400' ],
    proto   => 'tcp',
    action  => 'accept',
  } ->
  firewall { "${logstash_port} ${proto} logstash":
    port    => $logstash_port,
    proto   => $proto,
    action  => 'accept',
  } ->
  # Configure logstash and advanced logfilter UI
  class { "::openstack::logfilter":
     logstash_node      => $logstash_node,
     logstash_port      => $logstash_port,
     elasticsearch_node => $elasticsearch_node,
     kibana_host        => $kibana_host,
     kibana_port        => $kibana_port,
  }
}

  class {"::openstack::logrotate":
    rotation       => $rotation,
    keep           => $keep,
    limitsize      => $limitsize,
  }
}
