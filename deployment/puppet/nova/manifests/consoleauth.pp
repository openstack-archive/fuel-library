#
# Installs and configures consoleauth service
#
# The consoleauth service is required for vncproxy auth
# for Horizon
#
class nova::consoleauth(
  $enabled = false
) {

  include nova::params

  nova::generic_service { 'consoleauth':
    enabled      => $enabled,
    package_name => $::nova::params::consoleauth_package_name,
    service_name => $::nova::params::consoleauth_service_name,
  }

}
