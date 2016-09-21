# == Class: openstack::logging
#
# This class is for configuring rsyslog server/client logging
#
# === Parameters
#
# [*role*]
#  (optional) log server or client
#  Defaults to 'client'
#
# [*log_remote*]
#  (optional) send logs to remote server(s). Can be used with local logging.
#  Defaults to true.
#
# [*log_local*]
#  (optional) local logging. Can be used with remote logging.
# Defaults to false.
#
# [*log_auth_local*]
#  (optional) auth logging. Can be used with remote logging.
#  Defaults to false.
#
# [*rotation*]
#  (optional) logrotate option for rotation period - daily, weekly, monthly,
#  yearly.
#  Defaults to 'daily'.
#
# [*keep*]
#  (optional) logrotate option for number or rotated log files to keep.
#  Defaults to '7'.
#
# [*minsize*]
#  (optional) rotate log files periodically only if bigger than this value
#  Defaults to '10M'.
#
# [*maxsize*]
#  (optional) force rotate if this value has been exceeded
#  Defaults to '100M'.
#
# [*rservers*]
#  (optional) array of hashes which represents remote logging servers for
#  client role.
#  Defaults to [{'remote_type' => 'udp', 'server' => 'master', 'port' =>'514'},]
#
# [*port*]
#  (optional) port to use by server role for remote logging.
#  Defaults to 514.
#
# [*proto*]
#  (optional) tcp/udp/both proto(s) for remote log server role.
#  Defaults to 'udp'.
#
# [*show_timezone*]
#  (optional) if enabled, high_precision_timestamps (date-rfc3339) with GMT
#  would be used
#  for logging. Default is false (date-rfc3164), examples:
#    date-rfc3339: 2010-12-05T02:21:41.889482+01:00,
#    date-rfc3164: Dec 5 02:21:13,
#  Defaults to false.
#
# [*virtual*]
#  (optional) if node is virtual, fix for udp checksums should be applied
#  Defaults to false.
#
# [*rabbit_log_level*]
#  assign syslog log level for all rabbit messages which are not an ERROR
#  (rabbit does not support syslog, imfile is used for log capturing)
#  Defaults to 'NOTICE'.
#
# [*production*]
#  (optional)
#  Defaults to 'prod'.
#
# [*escapenewline*]
#  (optional) If set to true, rsyslog will be configured with
#  EscapeControlCharactersOnReceive = on. This directive instructs rsyslogd to
#  replace control characters during reception of the message. The intent is
#  to provide a way to stop non-printable messages from entering the syslog
#  system as whole. If this option is turned on, all control-characters are
#  converted to a 3-digit octal number and be prefixed with the
#  parser.controlCharacterEscapePrefix character (being '#' by default). For
#  example, if the BEL character (ctrl-g) is included in the message, it would
#  be converted to "#007". To be compatible to sysklogd, this option must be
#  turned on.
#  Defaults to false.
#
# [*debug*]
#  (optional)
#  Defaults to false.
#
# [*rabbit_fqdn_prefix*]
#  (optional)
#  Defaults to ''.
#
# [*ironic_collector*]
#  (optional)
#  Defaults to false.
#

class openstack::logging (
    $role               = 'client',
    $log_remote         = true,
    $log_local          = false,
    $log_auth_local     = false,
    $rotation           = 'daily',
    $keep               = '7',
    $minsize            = '10M',
    $maxsize            = '100M',
    $rservers           = [{'remote_type'=>'udp', 'server'=>'master', 'port'=>'514'},],
    $port               = '514',
    $proto              = 'udp',
    $show_timezone      = false,
    $virtual            = false,
    $rabbit_log_level   = 'NOTICE',
    $rabbit_fqdn_prefix = '',
    $production         = 'prod',
    $escapenewline      = false,
    $debug              = false,
    $ironic_collector   = false,
) {

  validate_re($proto, 'tcp|udp|both')
  validate_re($role, 'client|server')
  validate_re($rotation, 'daily|weekly|monthly|yearly')

  # Fix for udp checksums should be applied if running on virtual node
  if $virtual {
    class { '::openstack::checksum_udp' : port => $port }
  }

  # Configure syslog roles
  if $role == 'client' {

    # configure service to load 'imfile' module once in the global config,
    # next in the extra_modules as a workaround to not load in the snippets
    class { '::rsyslog':
      modules       => [
        '$ModLoad imuxsock # provides support for local system logging',
        '$ModLoad imklog   # provides kernel logging support (previously done by rklogd)',
        '#$ModLoad immark  # provides --MARK-- message capability',
        '$ModLoad imfile   # provides the ability to convert any standard text file into a syslog message',
      ],
      extra_modules => [ 'imfile' ],
    }

    if $rservers == undef {
      fail('Please provide a valid $rservers configuration')
    } else {
      $rservers_real = $rservers
    }

    # Configure logging templates for rsyslog client side
    # Rabbitmq does not support syslogging, use imfile
    ::rsyslog::imfile { '04-rabbitmq' :
      file_name     => "/var/log/rabbitmq/rabbit@${rabbit_fqdn_prefix}${::hostname}.log",
      file_tag      => 'rabbitmq',
      file_facility => 'syslog',
      file_severity => $rabbit_log_level,
    }

    ::rsyslog::imfile { '04-rabbitmq-sasl' :
      file_name     => "/var/log/rabbitmq/rabbit@${rabbit_fqdn_prefix}${::hostname}-sasl.log",
      file_tag      => 'rabbitmq-sasl',
      file_facility => 'syslog',
      file_severity => $rabbit_log_level,
    }

    ::rsyslog::imfile { '04-rabbitmq-startup_err' :
      file_name     => '/var/log/rabbitmq/startup_err',
      file_tag      => 'rabbitmq-startup_err',
      file_facility => 'syslog',
      file_severity => 'ERROR',
    }

    ::rsyslog::imfile { '04-rabbitmq-startup_log' :
      file_name     => '/var/log/rabbitmq/startup_log',
      file_tag      => 'rabbitmq-startup_log',
      file_facility => 'syslog',
      file_severity => $rabbit_log_level,
    }

    ::rsyslog::imfile { '04-rabbitmq-shutdown_err' :
      file_name     => '/var/log/rabbitmq/shutdown_err',
      file_tag      => 'rabbitmq-shutdown_err',
      file_facility => 'syslog',
      file_severity => 'ERROR',
    }

    ::rsyslog::imfile { '04-rabbitmq-shutdown_log' :
      file_name     => '/var/log/rabbitmq/shutdown_log',
      file_tag      => 'rabbitmq-shutdown_log',
      file_facility => 'syslog',
      file_severity => $rabbit_log_level,
    }

    ::rsyslog::imfile { '05-apache2-error':
      file_name     => '/var/log/apache2/error.log',
      file_tag      => 'apache2_error',
      file_facility => 'syslog',
      file_severity => 'ERROR',
    }

    ::rsyslog::imfile { '11-horizon_access':
      file_name     => '/var/log/apache2/horizon_access.log',
      file_tag      => 'horizon_access',
      file_facility => 'syslog',
      file_severity => 'INFO',
    }

    ::rsyslog::imfile { '11-horizon_error':
      file_name     => '/var/log/apache2/horizon_error.log',
      file_tag      => 'horizon_error',
      file_facility => 'syslog',
      file_severity => 'ERROR',
    }

    ::rsyslog::imfile { '12-keystone_wsgi_admin_access':
      file_name     => '/var/log/apache2/keystone_wsgi_admin_access.log',
      file_tag      => 'keystone_wsgi_admin_access',
      file_facility => 'syslog',
      file_severity => 'INFO',
    }

    ::rsyslog::imfile { '12-keystone_wsgi_admin_error':
      file_name     => '/var/log/apache2/keystone_wsgi_admin_error.log',
      file_tag      => 'keystone_wsgi_admin_error',
      file_facility => 'syslog',
      file_severity => 'ERROR',
    }

    ::rsyslog::imfile { '13-keystone_wsgi_main_access':
      file_name     => '/var/log/apache2/keystone_wsgi_main_access.log',
      file_tag      => 'keystone_wsgi_main_access',
      file_facility => 'syslog',
      file_severity => 'INFO',
    }

    ::rsyslog::imfile { '13-keystone_wsgi_main_error':
      file_name     => '/var/log/apache2/keystone_wsgi_main_error.log',
      file_tag      => 'keystone_wsgi_main_error',
      file_facility => 'syslog',
      file_severity => 'ERROR',
    }

    # mco does not support syslog also, hence use imfile
    ::rsyslog::imfile { '61-mco_agent_debug' :
      file_name     => '/var/log/mcollective.log',
      file_tag      => 'mcollective',
      file_facility => 'daemon',
      file_severity => 'DEBUG',
    }

    ::rsyslog::imfile { '10-dpkg' :
      file_name     => '/var/log/dpkg.log',
      file_tag      => 'dpkg',
      file_facility => 'syslog',
      file_severity => 'INFO',
    }

    # OS syslog configs for rsyslog client
    ::rsyslog::snippet { '10-nova':
      content => template("${module_name}/10-nova.conf.erb"),
    }

    ::rsyslog::snippet { '20-keystone':
      content => template("${module_name}/20-keystone.conf.erb"),
    }

    ::rsyslog::snippet { '30-cinder':
      content => template("${module_name}/30-cinder.conf.erb"),
    }

    ::rsyslog::snippet { '40-glance':
      content => template("${module_name}/40-glance.conf.erb"),
    }

    ::rsyslog::snippet { '50-neutron':
      content => template("${module_name}/50-neutron.conf.erb"),
    }

    ::rsyslog::snippet { '51-ceilometer':
      content => template("${module_name}/51-ceilometer.conf.erb"),
    }

    ::rsyslog::snippet { '53-aodh':
      content => template("${module_name}/53-aodh.conf.erb"),
    }

    ::rsyslog::snippet { '55-murano':
      content => template("${module_name}/55-murano.conf.erb"),
    }

    ::rsyslog::snippet { '54-heat':
      content => template("${module_name}/54-heat.conf.erb"),
    }

    ::rsyslog::snippet { '02-ha':
      content => template("${module_name}/02-ha.conf.erb"),
    }

    ::rsyslog::snippet { '03-dashboard':
      content => template("${module_name}/03-dashboard.conf.erb"),
    }

    ::rsyslog::snippet { '04-mysql':
      content => template("${module_name}/04-mysql.conf.erb"),
    }

    ::rsyslog::snippet { '60-puppet-apply':
      content => template("${module_name}/60-puppet-apply.conf.erb"),
    }

    ::rsyslog::snippet { '61-mco-nailgun-agent':
      content => template("${module_name}/61-mco-nailgun-agent.conf.erb"),
    }

    ::rsyslog::snippet { '62-mongod':
      content => template("${module_name}/62-mongod.conf.erb"),
    }

    if $ironic_collector {
      ::rsyslog::snippet { '70-ironic':
        content => template("${module_name}/70-ironic.conf.erb"),
      }
    }

    ::rsyslog::snippet { '80-swift':
      content => template("${module_name}/80-swift.conf.erb"),
    }

    # Custom settings for rsyslog default system file
    # WARNING: don't change the filename (same used in the syslog package)
    ::rsyslog::snippet { '50-default':
      content => template("${module_name}/50-default.conf.erb"),
    }

    # Custom settings for rsyslog client to define local logging
    ::rsyslog::snippet { '90-local':
      content => template("${module_name}/90-local.conf.erb"),
    }

    # Custom settings for rsyslog client to define remote logging
    # WARNING: don't change the filename (same used in the fuel-agent)
    ::rsyslog::snippet { '00-remote':
      content => template("${module_name}/00-remote.conf.erb"),
    }

    # TODO(mmalchuk) local and remote settings should be moved from snippets
    # into rsyslog::client class when it will be able to use $custom_config
    # together with $custom_params options in upstream module.

    # Custom settings for rsyslog configuration with minimal configuration.
    class { '::rsyslog::client':
      log_remote                => false,
      high_precision_timestamps => $show_timezone,
    }

    unless $escapenewline {
      ::rsyslog::snippet{ '00-disable-EscapeControlCharactersOnReceive':
        content => '$EscapeControlCharactersOnReceive off'
      }
    }

  } else { # server

    if $proto == 'both' {
      firewall { "${port} udp rsyslog":
        port   => $port,
        proto  => 'udp',
        action => 'accept',
      }
      firewall { "${port} tcp rsyslog":
        port   => $port,
        proto  => 'tcp',
        action => 'accept',
      }
    } else {
      firewall { "${port} ${proto} rsyslog":
        port   => $port,
        proto  => $proto,
        action => 'accept',
      }
    }

    $enable_tcp = $proto ? { 'tcp' => true, 'both' => true, default => false }
    $enable_udp = $proto ? { 'udp' => true, 'both' => true, default => true }

    class { '::rsyslog::server':
      enable_tcp                => $enable_tcp,
      enable_udp                => $enable_udp,
      server_dir                => '/var/log/',
      high_precision_timestamps => $show_timezone,
      port                      => $port,
    }

    ::rsyslog::snippet{ '00-disable-EscapeControlCharactersOnReceive':
      content => '$EscapeControlCharactersOnReceive off'
    }

    ::rsyslog::snippet{ '01-maxopenfiles':
      content => '$MaxOpenFiles 16384'
    }

    # Fuel specific config for logging parse formats used for /var/log/remote
    ::rsyslog::snippet { '30-remote-log':
        content => template("${module_name}/30-server-remote-log.conf.erb"),
    }
  }

  include ::rsyslog::params
  $rsyslog_service_name = $::rsyslog::params::service_name
  Rsyslog::Snippet <| |> -> Service[$rsyslog_service_name]

  # Configure log rotation
  class { '::openstack::logrotate':
    role     => $role,
    rotation => $rotation,
    keep     => $keep,
    minsize  => $minsize,
    maxsize  => $maxsize,
    debug    => $debug,
  }

  # Deprecated stuff handling section
  # Use this section to ensure the absence of the deprecated config
  # options for an Openstack services, or any other custom for Fuel
  # changes what should be removed forcibly.
  # (only if it couldn't be done in the synced upstream modules as well)

  # Ensure all OS services logging reconfiguration for deleted log_configs
  # (log_config was deprecated and should be removed from existing configs)
  # lint:ignore:80chars
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
  # lint:endignore
}
