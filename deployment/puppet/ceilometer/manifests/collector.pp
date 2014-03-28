# Installs the ceilometer collector service
#
# == Params
#  [*enabled*]
#    should the service be enabled
#
class ceilometer::collector (
  $enabled = true,
) {

  include ceilometer::params

  Ceilometer_config<||> ~> Service['ceilometer-collector']

  Package['ceilometer-collector'] -> Service['ceilometer-collector']
  package { 'ceilometer-collector':
    ensure => installed,
    name   => $::ceilometer::params::collector_package_name,
  }

  tweaks::ubuntu_service_override { 'ceilometer-collector' :}

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['ceilometer-common'] -> Service['ceilometer-collector']
  service { 'ceilometer-collector':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::collector_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => Class['ceilometer::db'],
    subscribe  => Exec['ceilometer-dbsync']
  }
  Package<| title == 'ceilometer-collector' or title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-collector'|>
  if !defined(Service['ceilometer-collector']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-collector\
 on packages update": }
  }

}
