class nova::api(
  $enabled=false
) inherits nova {

  # TODO what exactly is this for?
  # This resource is adding a great deal of comlexity to the overall
  # modules. Removing it would be great
  exec { "initial-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    refreshonly => true,
    require     => [Package[$::nova::params::common_package_name], Nova_config['sql_connection']],
  }

  Package<| title == 'nova-api' |> -> Exec['initial-db-sync']

  nova::generic_service { 'api':
    enabled      => $enabled,
    package_name => $::nova::params::api_package_name,
    service_name => $::nova::params::api_service_name,
  }
}
