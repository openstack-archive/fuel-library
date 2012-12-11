#
# Installs and configures consoleauth service
#
# The consoleauth service is required for vncproxy auth
# for Horizon
#
class nova::consoleauth(
  $enabled        = false,
  $ensure_package = 'present',
) {

  include nova::params

  nova::generic_service { 'consoleauth':
    enabled        => $enabled,
    package_name   => $::nova::params::consoleauth_package_name,
    service_name   => $::nova::params::consoleauth_service_name,
    ensure_package => $ensure_package,
  }

#  nova::generic_service { 'console':
#    enabled      => $enabled,
#    service_name => $::nova::params::console_service_name,
#    package_name => false,
#  }


}
