class heat::api_cloudwatch (
  $firewall_rule_name = '206 heat-api-cloudwatch',
  $bind_host          = '0.0.0.0',
  $bind_port          = '8003',
) {

  include heat::params

  validate_string($keystone_password)

  package { 'heat-api-cloudwatch':
    ensure => installed,
    name   => $::heat::params::api_cloudwatch_package_name,
  }

  service { 'heat-api-cloudwatch':
    ensure     => 'running',
    name       => $::heat::params::api_cloudwatch_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  Package['heat-common'] -> Package['heat-api-cloudwatch'] -> Heat_config<||>
  Heat_config<||> ~> Service['heat-api-cloudwatch']
  Package['heat-api-cloudwatch'] ~> Service['heat-api-cloudwatch']
  Class['heat::db'] -> Service['heat-api-cloudwatch']
  Exec['heat_db_sync'] -> Service['heat-api-cloudwatch'] 

}
