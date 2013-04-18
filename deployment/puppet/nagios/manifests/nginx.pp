class nagios::nginx(
$port           = '8099',
$server_name    = ['localhost','nagios.your-domain-name.com'],
$nagios3pkg     = $nagios::params::nagios3pkg,
$nginx_pkgs     = $nagios::params::nginx_pkgs,
$apache_service = $nagios::params::apache_service,
$nginx_service  = $nagios::params::nginx_service,
$php_service    = $nagios::params::php_service,
$fcgiwrap_service = $nagios::params::fcgiwrap_service,
$nginx_sites_enabled = $nagios::params::nginx_sites_enabled,
$nagios_name = $nagios::params::nagios_os_name,
$apache_user = $nagios::params::apache_user,

) inherits nagios::params {

#  service {$apache_service:
#    enable => false,
#    ensure => stopped,
#  }->

  package {$nginx_pkgs:
    require => Package[$nagios3pkg],
  }
  Exec {path => ['/bin','/sbin','/usr/sbin/','/usr/sbin/']}

  case $::osfamily {
    'Debian': {
      exec {'php-fpm':
        command     => 'sed -i "s%^\(\s*listen\s*=\).*$%\1 /var/run/php5-fpm.socket%" /etc/php5/fpm/pool.d/www.conf',
        notify      => Service['php-fpm'],
        subscribe   => Package[$nginx_pkgs],
        refreshonly => true,
      }
    }
    'RedHat': {
      File {before => Service[$php_service,$fcgiwrap_service]}
      file{'/etc/init.d/spawn-fcgi-php':
        mode   => '0755',
        source => 'puppet:///modules/nagios/nginx/init/spawn-fcgi-php',
      }
      
      file {'/etc/sysconfig/spawn-fcgi-php':
        source => 'puppet:///modules/nagios/nginx/spawn-fcgi-php',
      }
      
      file {'/etc/sysconfig/spawn-fcgi':
        source => 'puppet:///modules/nagios/nginx/spawn-fcgi',
      }
    }
  }
  
  exec {'cgi.conf':
    command     => "sed -i 's%^\(url_html_path=\).*$%\1/%' /etc/${nagios_name}/cgi.cfg",
    require     => Package[$nginx_pkgs],
    subscribe   => Package[$nginx_pkgs],
    refreshonly => true,
  }

  exec {'nginx_user':
    command     => "sed -i 's%^\(user\).*$%\1 ${apache_user};%' /etc/nginx/nginx.conf",
    require     => Package[$nginx_pkgs],
    subscribe   => Package[$nginx_pkgs],
    refreshonly => true,
    notify      => Service[$nginx_service],
  }

   file {$nginx_sites_enabled:
    content     => template("nagios/nginx/${nagios_name}.erb"),
    require     => Package[$nginx_pkgs],
    notify      => Service[$nginx_service],
  }

  #file {'/etc/nginx/sites-enabled/default':
  #  ensure   => purged,
  #  require  => Package[$nginx_pkgs],
  #}
  
  Service {require => Package[$nginx_pkgs]}
  
  service {$php_service:
    ensure  => running,
    before => Service[$nginx_service],
  }
    service {$fcgiwrap_service:
    ensure  => running,
    before => Service[$nginx_service],
  }
    service {$nginx_service:
    ensure  => running,
  }
}
