# these parameters need to be accessed from several locations and
# should be considered to be constant
class horizon::params {

  $logdir      = '/var/log/horizon'
  $django_wsgi = '/usr/share/openstack-dashboard/openstack_dashboard/wsgi/django.wsgi'
  $manage_py   = '/usr/share/openstack-dashboard/manage.py'

  case $::osfamily {
    'RedHat': {
      $http_service                = 'httpd'
      $http_modwsgi                = 'mod_wsgi'
      $package_name                = 'openstack-dashboard'
      $config_file                 = '/etc/openstack-dashboard/local_settings'
      $httpd_config_file           = '/etc/httpd/conf.d/openstack-dashboard.conf'
      $httpd_listen_config_file    = '/etc/httpd/conf/httpd.conf'
      $root_url                    = '/dashboard'
      $apache_user                 = 'apache'
      $apache_group                = 'apache'
      $wsgi_user                   = 'dashboard'
      $wsgi_group                  = 'dashboard'
    }
    'Debian': {
      $http_service                = 'apache2'
      $config_file                 = '/etc/openstack-dashboard/local_settings.py'
      $httpd_listen_config_file    = '/etc/apache2/ports.conf'
      $root_url                    = '/horizon'
      $apache_user                 = 'www-data'
      $apache_group                = 'www-data'
      $wsgi_user                   = 'horizon'
      $wsgi_group                  = 'horizon'
      case $::operatingsystem {
        'Debian': {
            $package_name          = 'openstack-dashboard-apache'
            $httpd_config_file     = '/etc/apache2/sites-available/openstack-dashboard.conf'
        }
        default: {
            $package_name          = 'openstack-dashboard'
            $httpd_config_file     = '/etc/apache2/conf-available/openstack-dashboard.conf'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }
}
