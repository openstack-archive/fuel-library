# Class: rabbitmq::service
#
#   This class manages the rabbitmq server service itself.
#
# Parameters:
#
# Actions:
#
# Requires:
#
# Sample Usage:
#
class rabbitmq::service(
  $service_ensure   = $rabbitmq::service_ensure,
  $service_manage   = $rabbitmq::service_manage,
  $service_name     = $rabbitmq::service_name,
  # TODO (bogdando) add docs for new param
  $service_provider = $rabbitmq::service_provider,
) inherits rabbitmq {

  validate_re($service_ensure, '^(running|stopped)$')
  validate_bool($service_manage)

  if ($service_manage) {
    if $service_ensure == 'running' {
      $ensure_real = 'running'
      $enable_real = true
    } else {
      $ensure_real = 'stopped'
      $enable_real = false
    }

    if ($service_provider) {
      service { $service_name:
        ensure     => $ensure_real,
        enable     => $enable_real,
        hasstatus  => true,
        hasrestart => true,
        provider   => $service_provider,
      }
    } else {
      service { $service_name:
        ensure     => $ensure_real,
        enable     => $enable_real,
        hasstatus  => true,
        hasrestart => true,
      }
    }
  }

}
