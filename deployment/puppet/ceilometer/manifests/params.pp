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
      $api_package_name                = 'openstack-ceilometer-api'
      $collector_package_name          = 'openstack-ceilometer-collector'
      $agent_notification_package_name = 'openstack-ceilometer-notification'
      # notification agent is included in collector package:
      $alarm_package_name              = ['openstack-ceilometer-alarm']
      $common_package_name             = 'openstack-ceilometer-common'
      $client_package_name             = 'python-ceilometerclient'
      # service names
      $agent_central_service_name      = 'openstack-ceilometer-central'
      $agent_compute_service_name      = 'openstack-ceilometer-compute'
      $api_service_name                = 'openstack-ceilometer-api'
      $collector_service_name          = 'openstack-ceilometer-collector'
      $agent_notification_service_name = 'openstack-ceilometer-notification'
      $alarm_notifier_service_name     = 'openstack-ceilometer-alarm-notifier'
      $alarm_evaluator_service_name    = 'openstack-ceilometer-alarm-evaluator'
      $pymongo_package_name            = 'python-pymongo'
      $psycopg_package_name            = 'python-psycopg2'
      # db packages
      if $::operatingsystem == 'Fedora' and $::operatingsystemrelease >= 18 {
        # fallback to stdlib version, not provided on fedora
        $sqlite_package_name      = undef
      } else {
        $sqlite_package_name      = 'python-sqlite2'
      }

    }
    'Debian': {
      # package names
      $agent_central_package_name      = 'ceilometer-agent-central'
      $agent_compute_package_name      = 'ceilometer-agent-compute'
      $api_package_name                = 'ceilometer-api'
      $collector_package_name          = 'ceilometer-collector'
      $agent_notification_package_name = 'ceilometer-agent-notification'
      $common_package_name             = 'ceilometer-common'
      $client_package_name             = 'python-ceilometerclient'
      $alarm_package_name              = ['ceilometer-alarm-notifier','ceilometer-alarm-evaluator']
      # service names
      $agent_central_service_name      = 'ceilometer-agent-central'
      $agent_compute_service_name      = 'ceilometer-agent-compute'
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
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: \
${::operatingsystem}, module ${module_name} only support osfamily \
RedHat and Debian")
    }
  }
}
