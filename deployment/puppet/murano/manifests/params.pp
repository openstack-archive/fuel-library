class murano::params {

  # package names
  $murano_conductor_package_name = 'openstack-murano-virtualenv-murano-conductor'
  $murano_api_package_name       = 'openstack-murano-virtualenv-murano-api'
  $murano_dashboard_package_name = 'murano-dashboard'
  $murano_dashboard_deps         = [ 'python-babel' ]

  # service names
  $murano_conductor_service_name = 'openstack-murano-conductor'
  $murano_api_service_name       = 'openstack-murano-api'

}
