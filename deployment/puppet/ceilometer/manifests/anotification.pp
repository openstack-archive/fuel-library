# Installs the ceilometer anotificationservice
#
# == Params
#  [*enabled*]
#    should the service be enabled
#
class ceilometer::anotification (
  $enabled     = true,
  $use_neutron = false,
  $swift       = false,
) {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-agent-notification']

  Package['ceilometer-agent-notification'] -> Service['ceilometer-agent-notification']
  package { 'ceilometer-agent-notification':
    ensure => installed,
    name   => $::ceilometer::params::anotification_package,
  }

  tweaks::ubuntu_service_override { 'ceilometer-agent-notification' :}

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['ceilometer-common'] -> Service['ceilometer-agent-notification']


  if $use_neutron {
    include neutron::notify::ceilometer
    include nova::notify::ceilometer
    include glance::notify::ceilometer
    if $swift {
      class { 'swift::notify::ceilometer':
        enable_ceilometer => true,
      }
    }
    include cinder::notify::ceilometer

    service { 'ceilometer-agent-notification':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::anotification_service,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => [
        Class['ceilometer::db'],
        Class['ceilometer::api'],
        Class['neutron'],
        Class['nova'],
        Class['cinder::notify::ceilometer'],
        Class['glance'],
        Exec['ceilometer-dbsync'],
      ],
    }
  } else {
    include nova::notify::ceilometer
    include glance::notify::ceilometer
    if $swift {
      class { 'swift::notify::ceilometer':
        enable_ceilometer => true,
      }
    }
    include cinder::notify::ceilometer

    service { 'ceilometer-agent-notification':
      ensure     => $service_ensure,
      name       => $::ceilometer::params::anotification_service,
      enable     => $enabled,
      hasstatus  => true,
      hasrestart => true,
      require    => [
        Class['ceilometer::db'],
        Class['ceilometer::api'],
        Class['nova'],
        Class['cinder::notify::ceilometer'],
        Class['glance'],
        Exec['ceilometer-dbsync'],
      ],
    }
  }

  Package<| title == 'ceilometer-agent-notification' or title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-agent-notification'|>
  if !defined(Service['ceilometer-agent-notification']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-agent-notification\
 on packages update": }
  }
}
