class heat::params {
# package names
 case $::osfamily {
    'RedHat': {
      $api_package_name             = 'openstack-heat-api'
      $api_cloudwatch_package_name  = 'openstack-heat-api-cloudwatch'
      $api_cfn_package_name         = 'openstack-heat-api-cfn'
      $engine_package_name          = 'openstack-heat-engine'
      $common_package_name          = 'openstack-heat-common'
      $deps_pbr_package_name        = 'python-pbr'
      $deps_routes_package_name     = 'python-routes'
      $client_package_name          = 'python-heatclient'

      # service names
      $api_service_name             = 'openstack-heat-api'
      $api_cloudwatch_service_name  = 'openstack-heat-api-cloudwatch'
      $api_cfn_service_name         = 'openstack-heat-api-cfn'
      $engine_service_name          = 'openstack-heat-engine'

      $db_sync_command              = '/usr/bin/heat-manage db_sync'
      $legacy_db_sync_command       = '/usr/bin/python -m heat.db.sync'
      $heat_db_sync_command         = '/usr/local/bin/heat_db_sync'

    }
    'Debian': {
      $api_package_name             = 'heat-api'
      $api_cloudwatch_package_name  = 'heat-api-cloudwatch'
      $api_cfn_package_name         = 'heat-api-cfn'
      $engine_package_name          = 'heat-engine'
      $common_package_name          = 'heat-common'
      $deps_pbr_package_name        = 'python-pbr'
      $deps_routes_package_name     = 'python-routes'
      $client_package_name          = 'python-heatclient'

      # service names
      $api_service_name             = 'heat-api'
      $api_cloudwatch_service_name  = 'heat-api-cloudwatch'
      $api_cfn_service_name         = 'heat-api-cfn'
      $engine_service_name          = 'heat-engine'

      $db_sync_command              = '/usr/bin/heat-manage db_sync'
      $legacy_db_sync_command       = '/usr/bin/python -m heat.db.sync'
      $heat_db_sync_command         = '/usr/local/bin/heat_db_sync'

    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
