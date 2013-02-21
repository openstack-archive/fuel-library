# these parameters need to be accessed from several locations and
# should be considered to be constant
class horizon::params {

  $logdir = '/var/log/horizon'

  case $::osfamily {
    'RedHat': {
      $http_service              = 'httpd'
      $vhosts_file               = '/etc/httpd/conf.d/ssl.conf'
      $http_modwsgi              = 'mod_wsgi'
      $package_name              = 'openstack-dashboard'
      $httpd_listen_config_file  = '/etc/httpd/conf.d/ports.conf'
      $local_settings_path       = '/etc/openstack-dashboard/local_settings'
      $root_url                  = '/dashboard'
      $apache_user               = 'apache'
      $apache_group              = 'apache'
      $ssl_key_group             = 'root'
      $ssl_dir                   = '/etc/pki/tls'
    }
    'Debian': {
      $http_service              = 'apache2'
      $vhosts_file               = '/etc/apache2/sites-available/openstack-dashboard.conf'
      $local_settings_path       = '/etc/openstack-dashboard/local_settings.py'
      $httpd_listen_config_file  = '/etc/apache2/ports.conf'
      $http_modwsgi              = 'libapache2-mod-wsgi'
      $root_url                  = '/horizon'
      $apache_user               = 'www-data'
      $apache_group              = 'www-data'
      $ssl_key_group             = 'ssl-cert'
      $ssl_dir                   = '/etc/ssl'
      case $::operatingsystem {
        'Debian': {
            $package_name        = 'openstack-dashboard-apache'
        }
        default: {
            $package_name        = 'openstack-dashboard'
        }
      }
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}, module ${module_name} only support osfamily RedHat and Debian")
    }
  }

  $ssl_cert_file = "${ssl_dir}/certs/horizon.pem"
  $ssl_key_file  = "${ssl_dir}/private/horizon.key"
}
