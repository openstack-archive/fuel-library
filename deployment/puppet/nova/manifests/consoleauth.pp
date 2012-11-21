#
# Installs and configures consoleauth service
#
# The consoleauth service is required for vncproxy auth
# for Horizon
#
class nova::consoleauth(
  $enabled        = false,
  $ensure_package = 'present'
) {

  include nova::params

    file { "/tmp/consoleauth-memcached.patch":
      ensure => present,
      source => 'puppet:///modules/nova/consoleauth-memcached.patch'
    }
    exec { 'patch-consoleauth':
      path    => ["/usr/bin", "/usr/sbin"],
      command => "/usr/bin/patch -p1 -N -r - -d /usr/lib/${::nova::params::python_path}/nova/consoleauth </tmp/consoleauth-memcached.patch",
      returns => [0, 1],
      require => [ [File['/tmp/consoleauth-memcached.patch']],[Package['patch', 'python-nova']]], 
    } ->


  nova::generic_service { 'consoleauth':
    enabled        => $enabled,
    package_name   => $::nova::params::consoleauth_package_name,
    service_name   => $::nova::params::consoleauth_service_name,
    ensure_package => $ensure_package,
  }
  
#  nova::generic_service { 'console':
#    enabled	 => $enabled,
#    service_name => $::nova::params::console_service_name,
#    package_name => false,
#  }
    

}
