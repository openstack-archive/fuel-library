# Parameters for puppet-ceilometer
#
class ceilometer::params {

  $dbsync_command =
    'ceilometer-dbsync --config-file=/etc/ceilometer/ceilometer.conf'

  # ssl keys/certs
  $ssl_cert_file       = '/etc/keystone/ssl/certs/signing_cert.pem'
  $ssl_key_file        = '/etc/keystone/ssl/private/signing_key.pem'
  $ssl_ca_file         = '/etc/keystone/ssl/certs/ca.pem'

  case $::osfamily {
    'RedHat': {
      # package names
      $agent_central_package_name = 'openstack-ceilometer-central'
      $agent_compute_package_name = 'openstack-ceilometer-compute'
      $api_package_name           = 'openstack-ceilometer-api'
      $collector_package_name     = 'openstack-ceilometer-collector'
      $common_package_name        = 'openstack-ceilometer-common'
      $client_package_name        = 'python-ceilometerclient'
      $alarm_package              = 'openstack-ceilometer-alarm'
      $agent_notification_package = 'openstack-ceilometer-notification'
      # service names
      $agent_central_service_name = 'openstack-ceilometer-central'
      $agent_compute_service_name = 'openstack-ceilometer-compute'
      $api_service_name           = 'openstack-ceilometer-api'
      $collector_service_name     = 'openstack-ceilometer-collector'
      $alarm_evaluator_service    = 'openstack-ceilometer-alarm-evaluator'
      $alarm_notifier_service     = 'openstack-ceilometer-alarm-notifier'
      $agent_notification_service = 'openstack-ceilometer-notification'
    }
    'Debian': {
      # package names
      $agent_central_package_name = 'ceilometer-agent-central'
      $agent_compute_package_name = 'ceilometer-agent-compute'
      $api_package_name           = 'ceilometer-api'
      $collector_package_name     = 'ceilometer-collector'
      $common_package_name        = 'ceilometer-common'
      $client_package_name        = 'python-ceilometerclient'
      $alarm_package              = ['ceilometer-alarm-notifier', 'ceilometer-alarm-evaluator']
      $agent_notification_package = 'ceilometer-agent-notification'
      # service names
      $agent_central_service_name = 'ceilometer-agent-central'
      $agent_compute_service_name = 'ceilometer-agent-compute'
      $api_service_name           = 'ceilometer-api'
      $collector_service_name     = 'ceilometer-collector'
      $alarm_evaluator_service    = 'ceilometer-alarm-evaluator'
      $alarm_notifier_service     = 'ceilometer-alarm-notifier'
      $agent_notification_service = 'ceilometer-agent-notification'
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
