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
# [proto] tcp/udp/both proto(s) for remote log server role.
# [show_timezone] if enabled, high_precision_timestamps (date-rfc3339) with GMT would be used
#   for logging. Default is false (date-rfc3164), examples:
#     date-rfc3339: 2010-12-05T02:21:41.889482+01:00,
#     date-rfc3164: Dec 5 02:21:13,
# [virtual] if node is virtual, fix for udp checksums should be applied
# [rabbit_log_level] assign syslog log level for all rabbit messages which are not an ERROR
#   (rabbit does not support syslog, imfile is used for log capturing)
#
class openstack::logging (
    $role                           = 'client',
    $log_remote                     = true,
    $log_local                      = false,
    $log_auth_local                 = false,
    $rotation                       = 'daily',
    $keep                           = '7',
    $limitsize                      = '300M',
    $rservers                       = [{'remote_type'=>'udp', 'server'=>'master', 'port'=>'514'},],
    $port                           = '514',
    $proto                          = 'udp',
    $show_timezone                  = false,
    $virtual                        = false,
    $rabbit_log_level               = 'NOTICE',
    $production                     = 'prod',
    $escapenewline                  = false,
) {

  validate_re($proto, 'tcp|udp|both')
  validate_re($role, 'client|server')
  validate_re($rotation, 'daily|weekly|monthly|yearly')

  # Fix for udp checksums should be applied if running on virtual node
  if $virtual {
    class { "openstack::checksum_udp" : port => $port }
  }

  include ::rsyslog::params

  # Set access and notifications for rsyslog client
  File {
    owner => $::rsyslog::params::run_user,
    group => $::rsyslog::params::run_group,
    mode => 0640,
    notify  => Class["::rsyslog::service"],
  }

  # Configure syslog roles
  if $role == 'client' {

    if $rservers == undef {
      $rservers_real = [{'remote_type'=>$remote_type, 'server'=>$server, 'port'=>$port}]
    }
    else {
      $rservers_real = $rservers
    }

    # Configure logging templates for rsyslog client side
    # Rabbitmq does not support syslogging, use imfile
    ::rsyslog::imfile { "04-rabbitmq" :
      file_name     => "/var/log/rabbitmq/rabbit@${hostname}.log",
      file_tag      => "rabbitmq",
      file_facility => "syslog",
      file_severity => $rabbit_log_level,
      notify  => Class["::rsyslog::service"],
    }

    ::rsyslog::imfile { "04-rabbitmq-sasl" :
      file_name     => "/var/log/rabbitmq/rabbit@${hostname}-sasl.log",
      file_tag      => "rabbitmq-sasl",
      file_facility => "syslog",
      file_severity => $rabbit_log_level,
      notify  => Class["::rsyslog::service"],
    }

    ::rsyslog::imfile { "04-rabbitmq-startup_err" :
      file_name     => "/var/log/rabbitmq/startup_err",
      file_tag      => "rabbitmq-startup_err",
      file_facility => "syslog",
      file_severity => "ERROR",
      notify  => Class["::rsyslog::service"],
    }

    ::rsyslog::imfile { "04-rabbitmq-shutdown_err" :
      file_name     => "/var/log/rabbitmq/shutdown_err",
      file_tag      => "rabbitmq-shutdown_err",
      file_facility => "syslog",
      file_severity => "ERROR",
      notify  => Class["::rsyslog::service"],
    }

    # mco does not support syslog also, hence use imfile
    ::rsyslog::imfile { "61-mco_agent_debug" :
      file_name     => "/var/log/mcollective.log",
      file_tag      => "mcollective",
      file_facility => "daemon",
      file_severity => "DEBUG",
      notify  => Class["::rsyslog::service"],
    }

    # OS syslog configs for rsyslog client
    file { "${::rsyslog::params::rsyslog_d}10-nova.conf":
      ensure => present,
      content => template("${module_name}/10-nova.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}20-keystone.conf":
      ensure => present,
      content => template("${module_name}/20-keystone.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}/30-cinder.conf":
      ensure => present,
      content => template("${module_name}/30-cinder.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}40-glance.conf":
      ensure => present,
      content => template("${module_name}/40-glance.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}50-neutron.conf":
      ensure => present,
      content => template("${module_name}/50-neutron.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}51-ceilometer.conf":
      ensure => present,
      content => template("${module_name}/51-ceilometer.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}53-murano.conf":
      ensure => present,
      content => template("${module_name}/53-murano.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}54-heat.conf":
      ensure => present,
      content => template("${module_name}/54-heat.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}52-sahara.conf":
      ensure => present,
      content => template("${module_name}/52-sahara.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}02-ha.conf":
      ensure => present,
    content => template("${module_name}/02-ha.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}03-dashboard.conf":
      ensure => present,
      content => template("${module_name}/03-dashboard.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}04-mysql.conf":
      ensure => present,
      content => template("${module_name}/04-mysql.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}60-puppet-apply.conf":
      content => template("${module_name}/60-puppet-apply.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}/61-mco-nailgun-agent.conf":
      content => template("${module_name}/61-mco-nailgun-agent.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}70-zabbix-server.conf":
      content => template("openstack/70-zabbix-server.conf.erb"),
    }

    # Custom settings for rsyslog client to define remote logging and local options
    file { "${::rsyslog::params::rsyslog_d}90-local.conf":
      content => template("${module_name}/90-local.conf.erb"),
    }

    file { "${::rsyslog::params::rsyslog_d}00-remote.conf":
    content => template("${module_name}/00-remote.conf.erb"),
    }

    class { "::rsyslog::client":
      log_remote                => $log_remote,
      log_local                 => $log_local,
      log_auth_local            => $log_auth_local,
      escapenewline             => $escapenewline,
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

    if $production =~ /docker/ {
      $enable_tcp = false
      $enable_udp = false
    } else {
      $enable_tcp = $proto ? { 'tcp' => true, 'both' => true, default => false }
      $enable_udp = $proto ? { 'udp' => true, 'both' => true, default => true }
    }

    class {"::rsyslog::server":
      enable_tcp                 => $enable_tcp,
      enable_udp                 => $enable_udp,
      server_dir                 => '/var/log/',
      high_precision_timestamps  => $show_timezone,
      port                       => $port,
    }

    # Fuel specific config for logging parse formats used for /var/log/remote
    $logconf = "${::rsyslog::params::rsyslog_d}30-remote-log.conf"
    file { $logconf :
        content => template("${module_name}/30-server-remote-log.conf.erb"),
        require => Class['::rsyslog::server'],
    }

  }

  # Configure log rotation
  class {"::openstack::logrotate":
    role           => $role,
    rotation       => $rotation,
    keep           => $keep,
    limitsize      => $limitsize,
  }

  # Deprecated stuff handling section
  # Use this section to ensure the absence of the deprecated config
  # options for an Openstack services, or any other custom for Fuel
  # changes what should be removed forcibly.
  # (only if it couldn't be done in the synced upstream modules as well)

  # Ensure all OS services logging reconfiguration for deleted log_configs
  # (log_config was deprecated and should be removed from existing configs)
  Ceilometer_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Cinder_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Glance_api_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Glance_registry_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Heat_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Keystone_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Neutron_dhcp_agent_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Neutron_l3_agent_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Neutron_metadata_agent_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Neutron_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Nova_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Sahara_config <| title == 'DEFAULT/log_config' |> { ensure => absent }
  Murano_config <| title == 'DEFAULT/log_config' |> { ensure => absent }

  #TODO(bogdando) if 4.1.1 -> 5.0 upgrade will be supported later
  #  remove all existing rsyslog::imfile templates for Openstack
  #  and notify rsyslog service
}
