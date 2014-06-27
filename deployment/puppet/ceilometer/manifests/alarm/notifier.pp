# Installs the ceilometer alarm notifier service
#
# == Params
#  [*enabled*]
#    should the service be enabled
#  [*notifier_rpc_topic*]
#    define on which topic the notifier will have
#    access
#  [*rest_notifier_certificate_key*]
#    define the certificate key for the rest service
#  [*rest_notifier_certificate_file*]
#    define the certificate file for the rest service
#  [*rest_notifier_ssl_verify*]
#    should the ssl verify parameter be enabled
#
class ceilometer::alarm::notifier (
  $enabled                        = true,
  $notifier_rpc_topic             = undef,
  $rest_notifier_certificate_key  = undef,
  $rest_notifier_certificate_file = undef,
  $rest_notifier_ssl_verify       = true,
) {

  include ceilometer::params

  validate_bool($rest_notifier_ssl_verify)

  Ceilometer_config<||> ~> Service['ceilometer-alarm-notifier']

  Package[$::ceilometer::params::alarm_package_name] -> Service['ceilometer-alarm-notifier']
  Package[$::ceilometer::params::alarm_package_name] -> Package<| title == 'ceilometer-alarm' |>
  ensure_packages($::ceilometer::params::alarm_package_name)

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
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
