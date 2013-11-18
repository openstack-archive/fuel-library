class heat::api (
  $firewall_rule_name = '204 heat-api',
  $bind_host          = '0.0.0.0',
  $bind_port          = '8004',
) {

  include heat::params

  validate_string($keystone_password)

  package { 'python-routes':
    ensure => installed,
    name   => $::heat::params::deps_routes_package_name,
  }

  package { 'heat-api':
    ensure  => installed,
    name    => $::heat::params::api_package_name,
    require => Package['python-routes'],
  }

  service { 'heat-api':
    ensure     => 'running',
    name       => $::heat::params::api_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  Package['heat-common'] -> Package['heat-api'] -> Heat_config<||>
  Heat_config<||> ~> Service['heat-api']
  Package['heat-api'] ~> Service['heat-api']
  Class['heat::db'] -> Service['heat-api']
  Exec['heat_db_sync'] -> Service['heat-api'] 

}
