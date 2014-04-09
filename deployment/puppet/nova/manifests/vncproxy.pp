#
# configures nova vnc proxy
#
class nova::vncproxy(
  $enabled        = false,
  $host           = '0.0.0.0',
  $port           = '6080',
  $ensure_package = 'present'
) {

  include nova::params

  # TODO make this work on Fedora

  # See http://nova.openstack.org/runnova/vncconsole.html for more details.

  nova_config {
    'DEFAULT/novncproxy_host': value => $host;
    'DEFAULT/novncproxy_port': value => $port;
  }

  if ! defined(Package['python-numpy']) {
    package { 'python-numpy':
      ensure => present,
      name   => $::nova::params::numpy_package_name,
    }
  }
  nova::generic_service { 'vncproxy':
    enabled        => $enabled,
    package_name   => $::nova::params::vncproxy_package_name,
    service_name   => $::nova::params::vncproxy_service_name,
    ensure_package => $ensure_package,
    require        => Package['python-numpy']
  }

}
