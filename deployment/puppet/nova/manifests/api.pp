class nova::api(
  $enabled           = false,
  $ensure_package    = 'present',
) {

  include nova::params

  exec { 'initial-db-sync':
    command     => '/usr/bin/nova-manage db sync',
    refreshonly => true,
    require     => [Package[$::nova::params::common_package_name], Nova_config['sql_connection']],
  }

  Package<| title == 'nova-api' |> -> Exec['initial-db-sync']
    
    File<| title == '/etc/nova/api-paste.ini' |>
    
    File<| title == '/etc/nova/api-paste.ini' |> ~> Service['nova-api']

  nova::generic_service { 'api':
    enabled        => $enabled,
    ensure_package => $ensure_package,
    package_name   => $::nova::params::api_package_name,
    service_name   => $::nova::params::api_service_name,
  }

}
