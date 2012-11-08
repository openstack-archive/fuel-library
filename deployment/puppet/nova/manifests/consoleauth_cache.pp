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
  $nova_prefix = "/usr/lib/${::nova::params::python_path}/nova"

  File {
    require => Package[$consoleauth_package_name],
    notify  => Service[$::nova::params::consoleauth_service_name],
    #owner   => 'root',
    #group   => 'root',
    #mode    => '755',
  }

  file {
    "${nova_prefix}/consoleauth/manager.py":
      source => 'puppet:///modules/nova/consoleauth_manager.py';
    "${nova_prefix}/openstack/common/timeutils.py":
      source => 'puppet:///modules/nova/openstack_common_timeutils.py';
    "${nova_prefix}/openstack/common/jsonutils.py":
      source => 'puppet:///modules/nova/openstack_common_jsonutils.py';
  }

}
