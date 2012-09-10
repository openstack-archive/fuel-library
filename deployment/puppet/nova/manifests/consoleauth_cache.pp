#
# This is a temporary manifest that patches
# nova consoleauth to resolve the folowing issue:
#   https://bugs.launchpad.net/nova/+bug/989337
#
# This is only intended as a temporary fix and needs to be removed
# once the issue is resolved with upstream.
#
class nova::consoleauth_cache() {

  $consoleauth_package_name = $::osfamily ? { 'RedHat' => 'python-nova', default => $::nova::params::consoleauth_package_name }

  file { "/usr/lib/${::nova::params::python_path}/nova/consoleauth/manager.py":
    source  => 'puppet:///modules/nova/consoleauth_manager.py',
    require => Package[$consoleauth_package_name],
    notify  => Service[$::nova::params::consoleauth_service_name],
    #owner   => 'root',
    #group   => 'root',
    #mode    => '755',
  }

}
