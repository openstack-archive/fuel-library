#
# This class contains the platform differences for keystone
#
class keystone::params {
  $client_package_name = 'python-keystone'

  case $::osfamily {
    'Debian': {
      $package_name              = 'keystone'
      $service_name              = 'keystone'
      $keystone_wsgi_script_path = '/usr/lib/cgi-bin/keystone'
      case $::operatingsystem {
        'Debian': {
          $service_provider            = undef
          $keystone_wsgi_script_source = '/usr/share/keystone/wsgi.py'
        }
        default: {
          $service_provider            = 'upstart'
          $keystone_wsgi_script_source = 'puppet:///modules/keystone/httpd/keystone.py'
        }
      }
    }
    'RedHat': {
      $package_name                = 'openstack-keystone'
      $service_name                = 'openstack-keystone'
      $keystone_wsgi_script_path   = '/var/www/cgi-bin/keystone'
      $service_provider            = undef
      $keystone_wsgi_script_source = 'puppet:///modules/keystone/httpd/keystone.py'
    }
  }
}
