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
  $syslog_log_facility_murano   = 'local0',
  $syslog_log_facility_glance   = 'LOCAL2',
  $syslog_log_facility_cinder   = 'LOCAL3',
  $syslog_log_facility_neutron  = 'LOCAL4',
  $syslog_log_facility_nova     = 'LOCAL6',
  $syslog_log_facility_keystone = 'LOCAL7',
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

  ::rsyslog::imfile { "50-neutron-server_debug" :
      file_name     => "/var/log/neutron/server.log",
      file_tag      => "neutron-server",
      file_facility => $syslog_log_facility_neutron,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-ovs-cleanup_debug" :
      file_name     => "/var/log/neutron/ovs-cleanup.log",
      file_tag      => "neutron-ovs-cleanup",
      file_facility => $syslog_log_facility_neutron,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-rescheduling_debug" :
     file_name     => "/var/log/neutron/rescheduling.log",
     file_tag      => "neutron-rescheduling",
     file_facility => $syslog_log_facility_neutron,
     file_severity => "DEBUG",
     notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-ovs-agent_debug" :
      file_name     => "/var/log/neutron/ovs-agent.log",
      file_tag      => "neutron-agent-ovs",
      file_facility => $syslog_log_facility_neutron,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-l3-agent_debug" :
      file_name     => "/var/log/neutron/l3-agent.log",
      file_tag      => "neutron-agent-l3",
      file_facility => $syslog_log_facility_neutron,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-dhcp-agent_debug" :
      file_name     => "/var/log/neutron/dhcp-agent.log",
      file_tag      => "neutron-agent-dhcp",
      file_facility => $syslog_log_facility_neutron,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }
  ::rsyslog::imfile { "50-neutron-metadata-agent_debug" :
      file_name     => "/var/log/neutron/metadata-agent.log",
      file_tag      => "neutron-agent-metadata",
      file_facility => $syslog_log_facility_neutron,
      file_severity => "DEBUG",
      notify  => Class["rsyslog::service"],
  }

# openstack syslog compatible mode, would work only for debug case.
# because of its poor syslog debug messages quality, use local logs convertion
if $debug =~ /(?i)(true|yes)/ {
::rsyslog::imfile { "10-nova-api_debug" :
    file_name     => "/var/log/nova/api.log",
    file_tag      => "nova-api",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-cert_debug" :
    file_name     => "/var/log/nova/cert.log",
    file_tag      => "nova-cert",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-consoleauth_debug" :
    file_name     => "/var/log/nova/consoleauth.log",
    file_tag      => "nova-consoleauth",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-scheduler_debug" :
    file_name     => "/var/log/nova/scheduler.log",
    file_tag      => "nova-scheduler",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-network_debug" :
    file_name     => "/var/log/nova/network.log",
    file_tag      => "nova-network",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-compute_debug" :
    file_name     => "/var/log/nova/compute.log",
    file_tag      => "nova-compute",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-conductor_debug" :
    file_name     => "/var/log/nova/conductor.log",
    file_tag      => "nova-conductor",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "10-nova-objectstore_debug" :
    file_name     => "/var/log/nova/objectstore.log",
    file_tag      => "nova-objectstore",
    file_facility => $syslog_log_facility_nova,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "20-keystone_debug" :
    file_name     => "/var/log/keystone/keystone.log",
    file_tag      => "keystone",
    file_facility => $syslog_log_facility_keystone,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "30-cinder-api_debug" :
    file_name     => "/var/log/cinder/api.log",
    file_tag      => "cinder-api",
    file_facility => $syslog_log_facility_cinder,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "30-cinder-volume_debug" :
    file_name     => "/var/log/cinder/volume.log",
    file_tag      => "cinder-volume",
    file_facility => $syslog_log_facility_cinder,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "30-cinder-scheduler_debug" :
    file_name     => "/var/log/cinder/scheduler.log",
    file_tag      => "cinder-scheduler",
    file_facility => $syslog_log_facility_cinder,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "40-glance-api_debug" :
    file_name     => "/var/log/glance/api.log",
    file_tag      => "glance-api",
    file_facility => $syslog_log_facility_glance,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "40-glance-registry_debug" :
    file_name     => "/var/log/glance/registry.log",
    file_tag      => "glance-registry",
    file_facility => $syslog_log_facility_glance,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "53-murano-api_debug" :
    file_name     => "/var/log/murano/murano-api.log",
    file_tag      => "murano-api",
    file_facility => $syslog_log_facility_murano,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "53-murano-conductor_debug" :
    file_name     => "/var/log/murano/murano-conductor.log",
    file_tag      => "murano-conductor",
    file_facility => $syslog_log_facility_murano,
    file_severity => "DEBUG",
    notify  => Class["rsyslog::service"],
}
::rsyslog::imfile { "53-murano-repository_debug" :
    file_name     => "/var/log/murano/murano-repository.log",
    file_tag      => "murano-repository",
    file_facility => $syslog_log_facility_murano,
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

} #end if

  file { "${rsyslog::params::rsyslog_d}02-ha.conf":
    ensure => present,
    content => template("${module_name}/02-ha.conf.erb"),
  }

  file { "${rsyslog::params::rsyslog_d}03-dashboard.conf":
    ensure => present,
    content => template("${module_name}/03-dashboard.conf.erb"),
  }


  file { "${rsyslog::params::rsyslog_d}60-puppet-agent.conf":
    content => template("${module_name}/60-puppet-agent.conf.erb"),
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
