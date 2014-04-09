# == Class: nova::consoleauth
#
# Installs and configures consoleauth service
#
# The consoleauth service is required for vncproxy auth
# for Horizon
#
# === Parameters
#
# [*enabled*]
#   (optional) Whether the nova consoleauth service will be run
#   Defaults to false
#
# [*manage_service*]
#   (optional) Whether to start/stop the service
#   Defaults to true
#
# [*ensure_package*]
#   (optional) Whether the nova consoleauth package will be installed
#   Defaults to 'present'
#
class nova::consoleauth(
  $enabled        = false,
  $manage_service = true,
  $ensure_package = 'present'
) {

  include nova::params

  nova::generic_service { 'consoleauth':
    enabled        => $enabled,
    manage_service => $manage_service,
    package_name   => $::nova::params::consoleauth_package_name,
    service_name   => $::nova::params::consoleauth_service_name,
    ensure_package => $ensure_package,
    require        => User['nova'],
  }

}
