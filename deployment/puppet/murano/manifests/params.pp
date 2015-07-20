# == Class: murano::params
#
# Parameters for puppet-murano
#
class murano::params {
  $dbmanage_command         = 'murano-db-manage --config-file /etc/murano/murano.conf upgrade'
  $default_external_network = 'public'
  $rabbit_service_name      = 'rabbit-server-murano'

  case $::osfamily {
    'RedHat': {
      # package names
      $api_package_name          = 'openstack-murano-api'
      $common_package_name       = 'openstack-murano-common'
      $engine_package_name       = 'openstack-murano-engine'
      $pythonclient_package_name = 'openstack-python-muranoclient'
      $dashboard_package_name    = 'openstack-murano-dashboard'
      # service names
      $api_service_name          = 'murano-api'
      $engine_service_name       = 'murano-engine'
      # dashboard config file
      $local_settings_path       = '/etc/openstack-dashboard/local_settings'
      # rabbitmq init params
      $init_script_file          = 'rabbitmq-init-centos.erb'
      $init_install_cmd          = "chkconfig --add '/etc/init.d/${rabbit_service_name}'"
    }
    'Debian': {
      # package names
      $api_package_name          = 'murano-api'
      $common_package_name       = 'murano-common'
      $engine_package_name       = 'murano-engine'
      $pythonclient_package_name = 'python-muranoclient'
      $dashboard_package_name    = 'murano-dashboard'
      # service names
      $api_service_name          = 'murano-api'
      $engine_service_name       = 'murano-engine'
      # dashboard config file
      $local_settings_path       = '/etc/openstack-dashboard/local_settings.py'
      # rabbitmq init params
      $init_script_file          = 'rabbitmq-init-ubuntu.erb'
      $init_install_cmd          = "update-rc.d '${rabbit_service_name}' defaults"
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}"
      )
    }
  }
}
