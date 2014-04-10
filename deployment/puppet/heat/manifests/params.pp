# Parameters for puppet-heat
#
class heat::params {

  $dbsync_command =
    'heat-manage --config-file /etc/heat/heat.conf db_sync'

  case $::osfamily {
    'RedHat': {
      # package names
      $api_package_name = 'openstack-heat-api'
      $api_cloudwatch_package_name = 'openstack-heat-api-cloudwatch'
      $api_cfn_package_name = 'openstack-heat-api-cfn'
      $engine_package_name = 'openstack-heat-engine'
      $client_package_name = 'python-heatclient'
      $common_package_name = 'openstack-heat-common'
      # service names
      $api_service_name = 'openstack-heat-api'
      $api_cloudwatch_service_name = 'openstack-heat-api-cloudwatch'
      $api_cfn_service_name = 'openstack-heat-api-cfn'
      $engine_service_name = 'openstack-heat-engine'
    }
    'Debian': {
      # package names
      $api_package_name = 'heat-api'
      $api_cloudwatch_package_name = 'heat-api-cloudwatch'
      $api_cfn_package_name = 'heat-api-cfn'
      $engine_package_name = 'heat-engine'
      $client_package_name = 'python-heatclient'
      $common_package_name = 'heat-common'
      # service names
      $api_service_name = 'heat-api'
      $api_cloudwatch_service_name = 'heat-api-cloudwatch'
      $api_cfn_service_name = 'heat-api-cfn'
      $engine_service_name = 'heat-engine'
      # Operating system specific
      case $::operatingsystem {
        'Ubuntu': {
          $libvirt_group = 'libvirtd'
        }
        default: {
          $libvirt_group = 'libvirt'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat and Debian")
    }
  }
}
