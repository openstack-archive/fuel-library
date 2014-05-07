#
#
#

class rsyslog::client (
  $high_precision_timestamps = false,
  $log_remote     = true,
  $remote_type    = 'udp',
  $log_local      = true,
  $log_auth_local = true,
  $custom_config  = undef,
  $server         = 'master',
  $port           = '514',
  $escapenewline  = false,
  $rservers       = undef,
  $virtual        = false,
  $syslog_log_facility_murano   = 'LOG_LOCAL0',
  $syslog_log_facility_glance   = 'LOG_LOCAL2',
  $syslog_log_facility_cinder   = 'LOG_LOCAL3',
  $syslog_log_facility_neutron  = 'LOG_LOCAL4',
  $syslog_log_facility_nova     = 'LOG_LOCAL6',
  $syslog_log_facility_keystone = 'LOG_LOCAL7',
  $syslog_log_facility_heat     = 'LOG_LOCAL0',
  $syslog_log_facility_sahara   = 'LOG_LOCAL0',
  $log_level      = 'NOTICE',
  $debug          = false,
  ) inherits rsyslog {

# Fix for udp checksums should be applied if running on virtual node
if $virtual { include rsyslog::checksum_udp514 }

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

  #TODO(bogdando) move all logging/imfile templates to openstack::logging in 'I'
  # cut off 'LOG_' from facility names, if any
  $re = '^LOG_(\w+)$'
  $syslog_log_facility_glance_matched = regsubst($syslog_log_facility_glance, $re, '\1')
  $syslog_log_facility_cinder_matched = regsubst($syslog_log_facility_cinder, $re, '\1')
  $syslog_log_facility_neutron_matched = regsubst($syslog_log_facility_neutron, $re, '\1')
  $syslog_log_facility_nova_matched = regsubst($syslog_log_facility_nova, $re, '\1')
  $syslog_log_facility_keystone_matched = regsubst($syslog_log_facility_keystone, $re, '\1')
  $syslog_log_facility_murano_matched = regsubst($syslog_log_facility_murano, $re, '\1')
  $syslog_log_facility_heat_matched = regsubst($syslog_log_facility_heat, $re, '\1')
  $syslog_log_facility_sahara_matched = regsubst($syslog_log_facility_sahara, $re, '\1')

# Rabbitmq does not support syslogging, use imfile
# log_level should be >= global syslog_log_level option,
# otherwise none messages would have gone to syslog
  ::rsyslog::imfile { "04-rabbitmq" :
    file_name     => "/var/log/rabbitmq/rabbit@${hostname}.log",
    file_tag      => "rabbitmq",
    file_facility => "syslog",
    file_severity => $log_level,
    notify  => Class["rsyslog::service"],
  }

  ::rsyslog::imfile { "04-rabbitmq-sasl" :
    file_name     => "/var/log/rabbitmq/rabbit@${hostname}-sasl.log",
    file_tag      => "rabbitmq-sasl",
    file_facility => "syslog",
    file_severity => $log_level,
    notify  => Class["rsyslog::service"],
  }

  ::rsyslog::imfile { "04-rabbitmq-startup_err" :
    file_name     => "/var/log/rabbitmq/startup_err",
    file_tag      => "rabbitmq-startup_err",
    file_facility => "syslog",
    file_severity => "ERROR",
    notify  => Class["rsyslog::service"],
  }

  ::rsyslog::imfile { "04-rabbitmq-shutdown_err" :
    file_name     => "/var/log/rabbitmq/shutdown_err",
    file_tag      => "rabbitmq-shutdown_err",
    file_facility => "syslog",
    file_severity => "ERROR",
    notify  => Class["rsyslog::service"],
  }

  ::rsyslog::imfile { "61-mco_agent_debug" :
    file_name     => "/var/log/mcollective.log",
    file_tag      => "mcollective",
    file_facility => "daemon",
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
  }

  ::rsyslog::imfile { "50-neutron-server_debug" :
      file_name     => "/var/log/neutron/server.log",
      file_tag      => "neutron-server",
      file_facility => $syslog_log_facility_neutron_matched,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-ovs-cleanup_debug" :
      file_name     => "/var/log/neutron/neutron-ovs-cleanup.log",
      file_tag      => "neutron-ovs-cleanup",
      file_facility => $syslog_log_facility_neutron_matched,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-rescheduling_debug" :
     file_name     => "/var/log/neutron/rescheduling.log",
     file_tag      => "neutron-rescheduling",
     file_facility => $syslog_log_facility_neutron_matched,
     file_severity => "DEBUG",
     notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-ovs-agent_debug" :
      file_name     => "/var/log/neutron/openvswitch-agent.log",
      file_tag      => "neutron-agent-ovs",
      file_facility => $syslog_log_facility_neutron_matched,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-l3-agent_debug" :
      file_name     => "/var/log/neutron/l3-agent.log",
      file_tag      => "neutron-agent-l3",
      file_facility => $syslog_log_facility_neutron_matched,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-dhcp-agent_debug" :
      file_name     => "/var/log/neutron/dhcp-agent.log",
      file_tag      => "neutron-agent-dhcp",
      file_facility => $syslog_log_facility_neutron_matched,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-metadata-agent_debug" :
      file_name     => "/var/log/neutron/metadata-agent.log",
      file_tag      => "neutron-agent-metadata",
      file_facility => $syslog_log_facility_neutron_matched,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }

  # OS specific log file names
  case $::osfamily {
    'Debian': {
       $sapi                = '/var/log/sahara/sahara-api.log'
       $napi                = '/var/log/nova/nova-api.log'
       $ncert               = '/var/log/nova/nova-cert.log'
       $nauth               = '/var/log/nova/nova-consoleauth.log'
       $nschd               = '/var/log/nova/nova-scheduler.log'
       $nnetw               = '/var/log/nova/nova-network.log'
       $ncomp               = '/var/log/nova/nova-compute.log'
       $ncond               = '/var/log/nova/nova-conductor.log'
       $nobjs               = '/var/log/nova/nova-objectstore.log'
       $capi                = '/var/log/cinder/cinder-api.log'
       $cvol                = '/var/log/cinder/cinder-volume.log'
       $csch                = '/var/log/cinder/cinder-scheduler.log'
     }
    'RedHat': {
       $sapi                = '/var/log/sahara/api.log'
       $napi                = '/var/log/nova/api.log'
       $ncert               = '/var/log/nova/cert.log'
       $nauth               = '/var/log/nova/consoleauth.log'
       $nschd               = '/var/log/nova/scheduler.log'
       $nnetw               = '/var/log/nova/network.log'
       $ncomp               = '/var/log/nova/compute.log'
       $ncond               = '/var/log/nova/conductor.log'
       $nobjs               = '/var/log/nova/objectstore.log'
       $capi                = '/var/log/cinder/api.log'
       $cvol                = '/var/log/cinder/volume.log'
       $csch                = '/var/log/cinder/scheduler.log'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  # openstack syslog compatible mode, would work only for debug case.
  # because of its poor syslog debug messages quality, use local logs convertion
  if $debug {
    ::rsyslog::imfile { "10-nova-api_debug" :
        file_name     => $napi,
        file_tag      => "nova-api",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-cert_debug" :
        file_name     => $ncert,
        file_tag      => "nova-cert",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-consoleauth_debug" :
        file_name     => $nauth,
        file_tag      => "nova-consoleauth",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-scheduler_debug" :
        file_name     => $nschd,
        file_tag      => "nova-scheduler",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-network_debug" :
        file_name     => $nnetw,
        file_tag      => "nova-network",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-compute_debug" :
        file_name     => $ncomp,
        file_tag      => "nova-compute",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-conductor_debug" :
        file_name     => $ncond,
        file_tag      => "nova-conductor",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "10-nova-objectstore_debug" :
        file_name     => $nobjs,
        file_tag      => "nova-objectstore",
        file_facility => $syslog_log_facility_nova_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "20-keystone_debug" :
        file_name     => "/var/log/keystone/keystone.log",
        file_tag      => "keystone",
        file_facility => $syslog_log_facility_keystone_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "30-cinder-api_debug" :
        file_name     => $capi,
        file_tag      => "cinder-api",
        file_facility => $syslog_log_facility_cinder_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "30-cinder-volume_debug" :
        file_name     => $cvol,
        file_tag      => "cinder-volume",
        file_facility => $syslog_log_facility_cinder_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "30-cinder-scheduler_debug" :
        file_name     => $csch,
        file_tag      => "cinder-scheduler",
        file_facility => $syslog_log_facility_cinder_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "40-glance-api_debug" :
        file_name     => "/var/log/glance/api.log",
        file_tag      => "glance-api",
        file_facility => $syslog_log_facility_glance_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "40-glance-registry_debug" :
        file_name     => "/var/log/glance/registry.log",
        file_tag      => "glance-registry",
        file_facility => $syslog_log_facility_glance_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    # murano
    ::rsyslog::imfile { "53-murano-api_debug" :
        file_name     => "/var/log/murano/murano-api.log",
        file_tag      => "murano-api",
        file_facility => $syslog_log_facility_murano_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    # heat
    ::rsyslog::imfile { "54-heat_engine_debug" :
        file_name     => "/var/log/heat/heat-engine.log",
        file_tag      => "heat-engine",
        file_facility => $syslog_log_facility_heat_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "54-heat_api_debug" :
        file_name     => "/var/log/heat/heat-api.log",
        file_tag      => "heat-api",
        file_facility => $syslog_log_facility_heat_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "54-heat_api_cfn_debug" :
        file_name     => "/var/log/heat/heat-api-cfn.log",
        file_tag      => "heat-api-cfn",
        file_facility => $syslog_log_facility_heat_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "54-heat_api_cloudwatch_debug" :
        file_name     => "/var/log/heat/heat-api-cloudwatch.log",
        file_tag      => "heat-api-cloudwatch",
        file_facility => $syslog_log_facility_heat_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "54-heat_manage_debug" :
        file_name     => "/var/log/heat/heat-manage.log",
        file_tag      => "heat-manage",
        file_facility => $syslog_log_facility_heat_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    # sahara
    ::rsyslog::imfile { "52-sahara-api_debug" :
        file_name     => $sapi,
        file_tag      => "sahara-api",
        file_facility => $syslog_log_facility_sahara_matched,
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    # ceilometer
    # FIXME(bogdando) in 5.1 all imfile templates for OS will be removed
    #   and ceilometer facility hardcode will be fixed as well
    ::rsyslog::imfile { "55-ceilometer-agent-central_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-agent-central.log",
        file_tag      => "ceilometer-agent-central",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-alarm-evaluator_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-alarm-evaluator.log",
        file_tag      => "ceilometer-alarm-evaluator",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-api_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-api.log",
        file_tag      => "ceilometer-api",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-dbsync_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-dbsync.log",
        file_tag      => "ceilometer-dbsync",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-agent-notification_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-agent-notification.log",
        file_tag      => "ceilometer-agent-notification",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-alarm-notifier_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-alarm-notifier.log",
        file_tag      => "ceilometer-alarm-notifier",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-collector_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-collector.log",
        file_tag      => "ceilometer-collector",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
    ::rsyslog::imfile { "55-ceilometer-agent-compute_debug" :
        file_name     => "/var/log/ceilometer/ceilometer-agent-compute.log",
        file_tag      => "ceilometer-agent-compute",
        file_facility => "LOCAL0",
        file_severity => "DEBUG",
        notify  => Class["rsyslog::service"],
    }
  } else { #non debug case
    # standard logging configs for syslog client
    file { "${rsyslog::params::rsyslog_d}10-nova.conf":
      ensure => present,
      content => template("${module_name}/10-nova.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}20-keystone.conf":
      ensure => present,
      content => template("${module_name}/20-keystone.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}/30-cinder.conf":
      ensure => present,
      content => template("${module_name}/30-cinder.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}40-glance.conf":
      ensure => present,
      content => template("${module_name}/40-glance.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}50-neutron.conf":
      ensure => present,
      content => template("${module_name}/50-neutron.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}51-ceilometer.conf":
      ensure => present,
      content => template("${module_name}/51-ceilometer.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}53-murano.conf":
      ensure => present,
      content => template("${module_name}/53-murano.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}54-heat.conf":
      ensure => present,
      content => template("${module_name}/54-heat.conf.erb"),
    }

    file { "${rsyslog::params::rsyslog_d}52-sahara.conf":
      ensure => present,
      content => template("${module_name}/52-sahara.conf.erb"),
    }

  } #end if

  file { "${rsyslog::params::rsyslog_d}02-ha.conf":
    ensure => present,
    content => template("${module_name}/02-ha.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}03-dashboard.conf":
    ensure => present,
    content => template("${module_name}/03-dashboard.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}04-mysql.conf":
    ensure => present,
    content => template("${module_name}/04-mysql.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}60-puppet-apply.conf":
    content => template("${module_name}/60-puppet-apply.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}/61-mco-nailgun-agent.conf":
    content => template("${module_name}/61-mco-nailgun-agent.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}90-local.conf":
    content => template("${module_name}/90-local.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}00-remote.conf":
    content => template("${module_name}/00-remote.conf.erb"),
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
