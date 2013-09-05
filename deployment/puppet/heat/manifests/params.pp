# Parameters for puppet-heat
#
class heat::params {

  case $::osfamily {
    'RedHat': {
      # package names
      $api_package_name             = 'openstack-heat-api'
      $api_cloudwatch_package_name  = 'openstack-heat-api-cloudwatch'
      $api_cfn_package_name         = 'openstack-heat-api-cfn'
      $engine_package_name          = 'openstack-heat-engine'
      $common_package_name          = 'openstack-heat-common'
      # service names
      $api_service_name             = 'openstack-heat-api'
      $api_cloudwatch_service_name  = 'openstack-heat-api-cloudwatch'
      $api_cfn_service_name         = 'openstack-heat-api-cfn'
      $engine_service_name          = 'openstack-heat-engine'
      $heat_cli_package_name        = 'openstack-heat-cli'
      $db_sync_command              = '/usr/bin/heat-manage db_sync'
      $deps_pbr_package_name        = 'python-pbr'
      $deps_routes_package_name     = 'python-routes'
      $deps_routes_package_vesion   = '1.13-1.el6'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat")
    }
  }
}
