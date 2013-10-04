class heat::params {

  # package names
  $api_package_name             = 'openstack-heat-api'
  $api_cloudwatch_package_name  = 'openstack-heat-api-cloudwatch'
  $api_cfn_package_name         = 'openstack-heat-api-cfn'
  $engine_package_name          = 'openstack-heat-engine'
  $common_package_name          = 'openstack-heat-common'
  $heat_cli_package_name        = 'openstack-heat-cli'
  $deps_pbr_package_name        = 'python-pbr'
  $deps_routes_package_name     = 'python-routes'
  $client_package_name          = 'openstack-murano-virtualenv-python-heatclient'

  # service names
  $api_service_name             = 'openstack-heat-api'
  $api_cloudwatch_service_name  = 'openstack-heat-api-cloudwatch'
  $api_cfn_service_name         = 'openstack-heat-api-cfn'
  $engine_service_name          = 'openstack-heat-engine'

  $db_sync_command              = '/usr/bin/heat-manage db_sync'
  $legacy_db_sync_command       = '/usr/bin/python -m heat.db.sync'

}
