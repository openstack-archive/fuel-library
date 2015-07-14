# Installs the ceilometer alarm notifier service
#
# == Params
#  [*enabled*]
#    (optional) Should the service be enabled.
#    Defaults to true.
#
#  [*manage_service*]
#    (optional) Whether the service should be managed by Puppet.
#    Defaults to true.
#
#  [*notifier_rpc_topic*]
#    (optional) Define on which topic the notifier will have access.
#    Defaults to undef.
#
#  [*rest_notifier_certificate_key*]
#    (optional) Define the certificate key for the rest service.
#    Defaults to undef.
#
#  [*rest_notifier_certificate_file*]
#    (optional) Define the certificate file for the rest service.
#    Defaults to undef.
#
#  [*rest_notifier_ssl_verify*]
#    (optional) Should the ssl verify parameter be enabled.
#    Defaults to true.
#
class ceilometer::alarm::notifier (
  $manage_service                 = true,
  $enabled                        = true,
  $notifier_rpc_topic             = undef,
  $rest_notifier_certificate_key  = undef,
  $rest_notifier_certificate_file = undef,
  $rest_notifier_ssl_verify       = true,
) {

  include ::ceilometer::params

  validate_bool($rest_notifier_ssl_verify)

  Ceilometer_config<||> ~> Service['ceilometer-alarm-notifier']

  Package[$::ceilometer::params::alarm_package_name] -> Service['ceilometer-alarm-notifier']
  Package[$::ceilometer::params::alarm_package_name] -> Package<| title == 'ceilometer-alarm' |>
  ensure_packages($::ceilometer::params::alarm_package_name,
    { tag => 'openstack' }
  )

  if $manage_service {
    if $enabled {
      $service_ensure = 'running'
    } else {
      $service_ensure = 'stopped'
    }
  }

  Package['ceilometer-common'] -> Service['ceilometer-alarm-notifier']

  service { 'ceilometer-alarm-notifier':
    ensure     => $service_ensure,
    name       => $::ceilometer::params::alarm_notifier_service_name,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true
  }

  if $notifier_rpc_topic != undef {
    ceilometer_config {
      'alarm/notifier_rpc_topic' : value => $notifier_rpc_topic;
    }
  }
  if $rest_notifier_certificate_key  != undef {
    ceilometer_config {
      'alarm/rest_notifier_certificate_key' :value => $rest_notifier_certificate_key;
      'alarm/rest_notifier_ssl_verify'      :value => $rest_notifier_ssl_verify;
    }
  }
  if $rest_notifier_certificate_file != undef {
    ceilometer_config {
      'alarm/rest_notifier_certificate_file' :value => $rest_notifier_certificate_file;
    }
  }

}
