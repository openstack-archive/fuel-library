# Class: rabbitmq::service
#
#   This class manages the rabbitmq server service itself.
#
#   Jeff McCune <jeff@puppetlabs.com>
#
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
  $service_name = 'rabbitmq-server',
  $service_provider = undef,
  $ensure='running',
  $enabled=true
) {

  validate_re($ensure, '^(running|stopped)$')
  if $ensure == 'running' {
    Class['rabbitmq::service'] -> Rabbitmq_user<| |>
    Class['rabbitmq::service'] -> Rabbitmq_vhost<| |>
    Class['rabbitmq::service'] -> Rabbitmq_user_permissions<| |>
    $ensure_real = 'running'
    $enable_real = $enabled
  } else {
    $ensure_real = 'stopped'
    $enable_real = false
  }

  File <| title == '/etc/rabbitmq/enabled_plugins'|> -> Service[$service_name]
  Package<| title == 'rabbitmq-server'|> ~> Service<| title == $service_name|>
  if !defined(Service[$service_name]) {
    notify{ "Module ${module_name} cannot notify service ${service_name}\
 on package rabbitmq-server update": }
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
