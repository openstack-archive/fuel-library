# Installs & configure the heat API service

class heat::api (
  $firewall_rule_name = '204 heat-api',
  $enabled            = true,
  $bind_host          = '0.0.0.0',
  $bind_port          = '8004',
) {

  include heat
  include heat::params

  Heat_config<||> ~> Service['heat-api']

  Package['heat-api'] -> Heat_config<||>
  Package['heat-api'] -> Service['heat-api']

  package { 'heat-api':
    ensure => installed,
    name   => $::heat::params::api_package_name,
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'heat-api':
    ensure     => $service_ensure,
    name       => $::heat::params::api_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    require    => [Package['heat-common'],
                  Package['heat-api']],
    subscribe  => Exec['heat-dbsync'],
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  heat_config {
    'heat_api/bind_host'  : value => $bind_host;
    'heat_api/bind_port'  : value => $bind_port;
  }

  Package<| title == 'heat-api'|> ~> Service<| title == 'heat-api'|>
  if !defined(Service['heat-api']) {
    notify{ "Module ${module_name} cannot notify service heat-api on package update": }
  }

}
