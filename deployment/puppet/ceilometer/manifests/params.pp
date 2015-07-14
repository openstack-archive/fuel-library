# Parameters for puppet-ceilometer
#
class ceilometer::params {

  $dbsync_command  = 'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf'
  $expirer_command = 'ceilometer-expirer'
  $user            = 'ceilometer'

  case $::osfamily {
    'RedHat': {
      # package names
      $agent_central_package_name      = 'openstack-ceilometer-central'
      $agent_compute_package_name      = 'openstack-ceilometer-compute'
      $agent_polling_package_name      = 'openstack-ceilometer-polling'
      $api_package_name                = 'openstack-ceilometer-api'
      $collector_package_name          = 'openstack-ceilometer-collector'
      $agent_notification_package_name = 'openstack-ceilometer-notification'
      $alarm_package_name              = ['openstack-ceilometer-alarm']
      $common_package_name             = 'openstack-ceilometer-common'
      $client_package_name             = 'python-ceilometerclient'
      # service names
      $agent_central_service_name      = 'openstack-ceilometer-central'
      $agent_compute_service_name      = 'openstack-ceilometer-compute'
      $agent_polling_service_name      = 'openstack-ceilometer-polling'
      $api_service_name                = 'openstack-ceilometer-api'
      $collector_service_name          = 'openstack-ceilometer-collector'
      $alarm_notifier_service_name     = 'openstack-ceilometer-alarm-notifier'
      $alarm_evaluator_service_name    = 'openstack-ceilometer-alarm-evaluator'
      $pymongo_package_name            = 'python-pymongo'
      $psycopg_package_name            = 'python-psycopg2'
      $agent_notification_service_name = 'openstack-ceilometer-notification'
      $ceilometer_wsgi_script_path     = '/var/www/cgi-bin/ceilometer'
      $ceilometer_wsgi_script_source   = '/usr/lib/python2.7/site-packages/ceilometer/api/app.wsgi'
      $sqlite_package_name             = undef
    }
    'Debian': {
      # package names
      $agent_central_package_name      = 'ceilometer-agent-central'
      $agent_compute_package_name      = 'ceilometer-agent-compute'
      $agent_polling_package_name      = 'ceilometer-polling'
      $api_package_name                = 'ceilometer-api'
      $collector_package_name          = 'ceilometer-collector'
      $agent_notification_package_name = 'ceilometer-agent-notification'
      $common_package_name             = 'ceilometer-common'
      $client_package_name             = 'python-ceilometerclient'
      $alarm_package_name              = ['ceilometer-alarm-notifier','ceilometer-alarm-evaluator']
      # service names
      $agent_central_service_name      = 'ceilometer-agent-central'
      $agent_compute_service_name      = 'ceilometer-agent-compute'
      $agent_polling_service_name      = 'ceilometer-polling'
      $collector_service_name          = 'ceilometer-collector'
      $api_service_name                = 'ceilometer-api'
      $agent_notification_service_name = 'ceilometer-agent-notification'
      $alarm_notifier_service_name     = 'ceilometer-alarm-notifier'
      $alarm_evaluator_service_name    = 'ceilometer-alarm-evaluator'
      # db packages
      $pymongo_package_name            = 'python-pymongo'
      $psycopg_package_name            = 'python-psycopg2'
      $sqlite_package_name             = 'python-pysqlite2'

      # Operating system specific
      case $::operatingsystem {
        'Ubuntu': {
          $libvirt_group = 'libvirtd'
        }
        default: {
          $libvirt_group = 'libvirt'
        }
      }
      $ceilometer_wsgi_script_path    = '/usr/lib/cgi-bin/ceilometer'
      $ceilometer_wsgi_script_source  = '/usr/share/ceilometer/app.wsgi'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat and Debian")
    }
  }
}
