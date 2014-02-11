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
      $horizon_additional_packages = ['nodejs', 'nodejs-less', 'python-lesscpy']
      $httpd_listen_config_file  = '/etc/httpd/conf.d/ports.conf'
      $local_settings_path       = '/etc/openstack-dashboard/local_settings'
      $root_url                  = '/dashboard'
      $apache_user               = 'apache'
      $apache_group              = 'apache'
      $apache_confdir            = ['/etc/httpd', '/etc/httpd/conf.d']
      $ssl_key_group             = 'root'
      $ssl_cert_file             = '/etc/pki/tls/certs/localhost.crt'
      $ssl_key_file              = '/etc/pki/tls/private/localhost.key'
      $ssl_cert_type             = 'crt'
      $dashboard_http_conf_file  = '/etc/httpd/conf.d/openstack-dashboard.conf'
      $apache_tuning_file        = '/etc/httpd/conf.d/zzz_performance_tuning.conf'
    }
    'Debian': {
      $http_service              = 'apache2'
      $vhosts_file               = '/etc/apache2/sites-available/openstack-dashboard.conf'
      $local_settings_path       = '/etc/openstack-dashboard/local_settings.py'
      $httpd_listen_config_file  = '/etc/apache2/ports.conf'
      $http_modwsgi              = 'libapache2-mod-wsgi'
      $root_url                  = '/horizon'
      $apache_user               = 'horizon'
      $apache_group              = 'horizon'
      $apache_confdir            = '/etc/apache2'
      $ssl_key_group             = 'ssl-cert'
      $ssl_cert_file             = '/etc/ssl/certs/ssl-cert-snakeoil.pem'
      $ssl_key_file              = '/etc/ssl/private/ssl-cert-snakeoil.key'
      $ssl_cert_type             = 'pem'
      $dashboard_http_conf_file  = '/etc/apache2/conf-available/openstack-dashboard.conf'
      $apache_tuning_file        = '/etc/apache2/conf.d/zzz_performance_tuning.conf'
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

}
