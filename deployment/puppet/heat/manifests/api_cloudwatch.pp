# Installs & configure the heat CloudWatch API service

class heat::api_cloudwatch (
  $enabled           = true,
  $bind_host         = '0.0.0.0',
  $bind_port         = '8003',
  $workers           = '0'
) {

  include heat
  include heat::params

  Heat_config<||> ~> Service['heat-api-cloudwatch']

  Package['heat-api-cloudwatch'] -> Heat_config<||>
  Package['heat-api-cloudwatch'] ~> Service['heat-api-cloudwatch']
  package { 'heat-api-cloudwatch':
    ensure => installed,
    name   => $::heat::params::api_cloudwatch_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['heat-common'] -> Service['heat-api-cloudwatch']

  service { 'heat-api-cloudwatch':
    ensure     => $service_ensure,
    name       => $::heat::params::api_cloudwatch_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => Exec['heat-dbsync'],
  }

  heat_config {
    'heat_api_cloudwatch/bind_host'  : value => $bind_host;
    'heat_api_cloudwatch/bind_port'  : value => $bind_port;
    'heat_api_cloudwatch/workers'    : value => $workers;
  }
}
