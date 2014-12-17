import 'common/globals.pp'

$base_syslog_rserver  = {
  'remote_type' => 'tcp',
  'server' => $base_syslog_hash['syslog_server'],
  'port' => $base_syslog_hash['syslog_port']
}

$syslog_rserver = {
  'remote_type' => $syslog_hash['syslog_transport'],
  'server' => $syslog_hash['syslog_server'],
  'port' => $syslog_hash['syslog_port'],
}

if $syslog_hash['syslog_server'] != "" and $syslog_hash['syslog_port'] != "" and $syslog_hash['syslog_transport'] != "" {
  $rservers = [$base_syslog_rserver, $syslog_rserver]
} else {
  $rservers = [$base_syslog_rserver]
}

if $use_syslog {
  class { "::openstack::logging":
    stage          => 'first',
    role           => 'client',
    show_timezone  => true,
  # log both locally include auth, and remote
    log_remote     => true,
    log_local      => true,
    log_auth_local => true,
  # keep four weekly log rotations, force rotate if 300M size have exceeded
    rotation       => 'weekly',
    keep           => '4',
  # should be > 30M
    limitsize      => '300M',
  # remote servers to send logs to
    rservers       => $rservers,
  # should be true, if client is running at virtual node
    virtual        => str2bool($is_virtual),
  # Rabbit doesn't support syslog directly
    rabbit_log_level => 'NOTICE',
    debug            => $debug,
  }
}
