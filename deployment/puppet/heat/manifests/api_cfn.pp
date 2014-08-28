# Installs & configure the heat CloudFormation API service

class heat::api_cfn (
  $enabled           = true,
  $bind_host         = '0.0.0.0',
  $bind_port         = '8000',
  $workers           = '0'
) {

  include heat
  include heat::params

  Heat_config<||> ~> Service['heat-api-cfn']

  Package['heat-api-cfn'] -> Heat_config<||>
  Package['heat-api-cfn'] ~> Service['heat-api-cfn']
  package { 'heat-api-cfn':
    ensure => installed,
    name   => $::heat::params::api_cfn_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  Package['heat-common'] -> Service['heat-api-cfn']

  service { 'heat-api-cfn':
    ensure     => $service_ensure,
    name       => $::heat::params::api_cfn_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => Exec['heat-dbsync'],
  }

  heat_config {
    'heat_api_cfn/bind_host'              : value => $bind_host;
    'heat_api_cfn/bind_port'              : value => $bind_port;
    'heat_api_cfn/workers'                : value => $workers;
  }
}
