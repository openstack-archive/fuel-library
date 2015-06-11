# == Class: openstacklib::openstackclient
#
# Installs the openstackclient
#
# == Parameters
#
#  [*package_ensure*]
#    Ensure state of the openstackclient package.
#    Optional. Defaults to 'present'.
#
class openstacklib::openstackclient(
  $package_ensure = 'present',
){
  package { 'python-openstackclient':
    ensure => $package_ensure,
    tag    => 'openstack',
  }
}
