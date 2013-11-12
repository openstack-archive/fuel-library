class heat::api_cfn (
  $firewall_rule_name = '205 heat-api-cfn',
  $bind_host          = '0.0.0.0',
  $bind_port          = '8000',
) {

  include heat::params

  validate_string($keystone_password)

  package { 'heat-api-cfn':
    ensure => installed,
    name   => $::heat::params::api_cfn_package_name,
  }

  service { 'heat-api-cfn':
    ensure     => 'running',
    name       => $::heat::params::api_cfn_service_name,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
  }

  firewall { $firewall_rule_name :
    dport   => [ $bind_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  Package['heat-common'] -> Package['heat-api-cfn'] -> Heat_config<||>
  Heat_config<||> ~> Service['heat-api-cfn']
  Package['heat-api-cfn'] ~> Service['heat-api-cfn']
  Class['heat::db'] -> Service['heat-api-cfn']
  Exec['heat_db_sync'] -> Service['heat-api-cfn'] 

}
