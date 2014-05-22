# Installs the ceilometer agent notification service
#
# == Params
#  [*enabled*]
#    should the service be enabled
#
class ceilometer::agent_notification (
  $enabled     = true,
  $use_neutron = false,
  $swift       = false,
) {

  include ceilometer::params

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Ceilometer_config<||> ~> Service['ceilometer-agent-notification']

  case $::osfamily {
    'RedHat': {
      Package['ceilometer-common'] -> Service['ceilometer-agent-notification']
    }
    'Debian': {
      package { 'ceilometer-agent-notification':
        ensure => installed,
        name   => $::ceilometer::params::agent_notification_package,
      }

      tweaks::ubuntu_service_override { 'ceilometer-agent-notification' :}

      Package['ceilometer-agent-notification'] -> Service['ceilometer-agent-notification']
    }
  }


  ###FIXME(aglarendil): remove this stupid cross-class dependency 
  ###move notification driver configuration into particular
  ###classes
  include nova::notify::ceilometer
  include heat::notify::ceilometer

  if $swift {
      class { 'swift::notify::ceilometer':
        enable_ceilometer => true,
      }
    }


  if $use_neutron {
    include neutron::notify::ceilometer

    service { 'ceilometer-agent-notification':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::agent_notification_service,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => [
        Class['ceilometer::db'],
        Class['ceilometer::api'],
        Class['neutron'],
        Class['nova'],
        Class['glance'],
        Class['heat'],
        Exec['ceilometer-dbsync'],
      ],
    }
  } else {
    service { 'ceilometer-agent-notification':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::agent_notification_service,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => [
        Class['ceilometer::db'],
        Class['ceilometer::api'],
        Class['nova'],
        Class['glance'],
        Class['heat'],
        Exec['ceilometer-dbsync'],
      ],
    }
  }

  case $::osfamily {
    'RedHat': {
      Package<| title == 'ceilometer-collector' or title == 'ceilometer-common'|> ~>
      Service<| title == 'ceilometer-agent-notification'|>
      if !defined(Service['ceilometer-agent-notification']) {
      notify{ "Module ${module_name} cannot notify service ceilometer-notification\
 on packages update": }
      }
    }
    'Debian': {
      Package<| title == 'ceilometer-agent-notification' or title == 'ceilometer-common'|> ~>
      Service<| title == 'ceilometer-agent-notification'|>
      if !defined(Service['ceilometer-agent-notification']) {
      notify{ "Module ${module_name} cannot notify service ceilometer-agent-notification\
 on packages update": }
      }
    }
  }
}
