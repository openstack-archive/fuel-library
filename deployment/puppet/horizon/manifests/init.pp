#
# installs a horizon server
#
#
# - Parameters
# $secret_key           the application secret key (used to crypt cookies, etc. …). mandatory
# $cache_server_ip      memcached ip address (or VIP)
# $cache_server_port    memcached port
# $swift                (bool) is swift installed
# $quantum              (bool) is quantum installed
#   The next is an array of arrays, that can be used to add call-out links to the dashboard for other apps.
#   There is no specific requirement for these apps to be for monitoring, that's just the defacto purpose.
#   Each app is defined in two parts, the display name, and the URI
# [horizon_app_links]     array as in '[ ["Nagios","http://nagios_addr:port/path"],["Ganglia","http://ganglia_addr"] ]'
# $keystone_host        ip address/hostname of the keystone service
# $keystone_port        public port of the keystone service
# $keystone_scheme      http or https
# $keystone_default_role default keystone role for new users
# $django_debug         True/False. enable/disables debugging. defaults to false
# $api_result_limit     max number of Swift containers/objects to display on a single page
#
class horizon(
  $bind_address = '127.0.0.1',
  $secret_key,
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $swift                 = false,
  $quantum               = false,
  $package_ensure	= present,
  $horizon_app_links     = false,
  $keystone_host         = '127.0.0.1',
  $keystone_port         = 5000,
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $django_debug          = 'False',
  $api_result_limit      = 1000
) {

  include horizon::params

  package { ["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"]:
    ensure => present,
  }

  package { "$::horizon::params::package_name":
    ensure => $package_ensure,
    require => Package[$::horizon::params::http_service],
  }

  case $::osfamily {
    'RedHat': {
      File {
        require => Package["$::horizon::params::package_name"],
        owner   => 'apache',
        group   => 'apache',
      }
    }
    'Debian': {
      File {
        require => Package["$::horizon::params::package_name"],
        owner   => 'www-data',
        group   => 'www-data',
      }
    }
  }
 $dashboard_urlpart = $::osfamily ? {
   'Debian' => 'horizon',
   'RedHat' => 'dashboard'
 }
  file { $::horizon::params::local_settings_path:
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
  }

  file { $::horizon::params::logdir:
    ensure  => directory,
    mode    => '0751',
    before  => Service["$::horizon::params::http_service"],
  }

  case $::osfamily {
    'RedHat': { 
      file { '/etc/httpd/conf.d/wsgi.conf':
        mode   => 644,
        owner  => root,
        group  => root,
        content => "LoadModule wsgi_module modules/mod_wsgi.so\n",
        require => Package["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"],
        before  => Package["$::horizon::params::package_name"],
      }  # ensure there is a HTTP redirect from / to /dashboard
  file_line { 'horizon_redirect_rule':
    path => $::horizon::params::config_file,
    line => 'RedirectMatch permanent ^/$ /dashboard/',
    require => Package["$::horizon::params::package_name"],
    notify => Service["$::horizon::params::http_service"]
  }
  file_line { 'httpd_listen_on_internal_network_only':
    path => $::horizon::params::httpd_listen_config_file,
    match => '^Listen (.*)$',
    line => "Listen ${bind_address}:80",
    before => [Service["$::horizon::params::http_service"]],
    notify => [Service["$::horizon::params::http_service"]],
    require =>[Package["$::horizon::params::package_name"]] 
  }
 }
 'Debian': {
   file {'/etc/apache2':
     ensure => directory,
     require => []
   }
   file { $::horizon::params::httpd_listen_config_file: 
   content => template('horizon/ports.conf.erb'), 
   require => File['/etc/apache2'],
   before => Package[$::horizon::params::package_name],
   }
   exec { 'a2enmod wsgi':
     command => 'a2enmod wsgi',
     path => ['/usr/bin','/usr/sbin','/bin/','/sbin'],
     require => Package["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"],
     before  => Package["$::horizon::params::package_name"],
   }
 }
}
    service { '$::horizon::params::http_service':
      name      => $::horizon::params::http_service,
      ensure    => 'running',
      enable    => true,
      require   => Package["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"],
      subscribe => File["$::horizon::params::local_settings_path", "$::horizon::params::logdir"]
    }
  if $cache_server_ip =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['horizon']
  }
}
