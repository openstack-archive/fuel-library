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
  $secret_key,
  $bind_address          = '127.0.0.1',
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $swift                 = false,
  $quantum               = false,
  $package_ensure	 = present,
  $horizon_app_links     = false,
  $keystone_host         = '127.0.0.1',
  $keystone_port         = 5000,
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $django_debug          = 'False',
  $api_result_limit      = 1000,
  $http_port             = 80,
  $https_port            = 443,
  $use_ssl               = false,
) {

  include horizon::params

  $root_url      = $::horizon::params::root_url
  $wsgi_user     = $::horizon::params::apache_user
  $wsgi_group    = $::horizon::params::apache_group

  package { ["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"]:
    ensure => present,
  }

  package { "$::horizon::params::package_name":
    ensure => $package_ensure,
    require => Package[$::horizon::params::http_service],
  }

  File {
    require => Package["$::horizon::params::package_name"],
    owner   => $wsgi_user,
    group   => $wsgi_group,
  }

  file { $::horizon::params::local_settings_path:
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
  }

  case $use_ssl {
    'exist': { # SSL certificate already exists
      $sslcert_pair = regsubst([$::horizon::params::ssl_cert_file, $::horizon::params::ssl_key_file],
                        '(\S+\/)\S+(\.\S+)', "\1${::domain}\2")

      $ssl_cert_file = $sslcert_pair[0]
      $ssl_key_file  = $sslcert_pair[1]
    }

    'custom': { # upload signed certificate
      $sslcert_pair = regsubst([$::horizon::params::ssl_cert_file, $::horizon::params::ssl_key_file],
                        '(\S+\/)\S+(\.\S+)', "\1${::hostname}\2")

      $ssl_cert_file     = $sslcert_pair[0]
      $ssl_key_file      = $sslcert_pair[1]

      file { $ssl_cert_file:
        ensure  => present,
        mode    => '0644',
        owner   => 'root',
        group   => 'root',
        source  => "puppet:///ssl_certs/${::hostname}.${::horizon::params::ssl_cert_type}",
      }

      file { $ssl_key_file:
        ensure  => present,
        mode    => '0640',
        owner   => 'root',
        group   => $::horizon::params::ssl_key_group,
        source  => "puppet:///ssl_certs/${::hostname}.key",
      }
    }

    'default': { # use default package certificate
      $ssl_cert_file = $::horizon::params::ssl_cert_file
      $ssl_key_file  = $::horizon::params::ssl_key_file
    }
  }

  file { $::horizon::params::logdir:
    ensure  => directory,
    mode    => '0751',
    before  => Service["$::horizon::params::http_service"],
  }

  file { $::horizon::params::vhosts_file:
    content => template('horizon/vhosts.erb'),
    mode    => '0644',
    require => Package["$::horizon::params::package_name"],
    notify  => Service["$::horizon::params::http_service"]
  }

  file { $::horizon::params::httpd_listen_config_file: 
    content => template('horizon/ports.conf.erb'), 
    require => Package[$::horizon::params::package_name],
    #before  => Package[$::horizon::params::package_name],
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

      # file_line { 'horizon_redirect_rule':
      #   path => $::horizon::params::config_file,
      #   line => 'RedirectMatch permanent ^/$ /dashboard/',
      #   require => Package["$::horizon::params::package_name"],
      #   notify => Service["$::horizon::params::http_service"]
      # }

      # file_line { 'httpd_listen_on_internal_network_only':
      #   path => $::horizon::params::httpd_listen_config_file,
      #   match => '^Listen (.*)$',
      #   line => "Listen ${bind_address}:80",
      #   before => [Service["$::horizon::params::http_service"]],
      #   notify => [Service["$::horizon::params::http_service"]],
      #   require =>[Package["$::horizon::params::package_name"]] 
      # }

      if $use_ssl {
        package { 'mod_ssl':
          ensure => present,
          before => Service[$::horizon::params::http_service],
        }
      }

      augeas { "remove_listen_directive": 
        context => "/files/etc/httpd/conf/httpd.conf",
        changes => [ 
          "rm directive[. = 'Listen']"
        ],
        before  => Service[$::horizon::params::http_service],
      } 
    }
    'Debian': {
      file {'/etc/apache2':
        ensure => directory,
        require => []
      }

      A2mod {
        ensure  => present,
        require => Package[$::horizon::params::package_name],
        notify  => Service[$::horizon::params::http_service],
      }

      a2mod { 'wsgi': }

      if $use_ssl {
        a2mod { ['rewrite', 'ssl']: }
      }

      file { '/etc/apache2/sites-enabled/openstack-dashboard':
        ensure  => link,
        target  => $::horizon::params::vhosts_file,
        #require => File['/etc/apache2/sites-available/openstack-dashboard'],
      }

      file { '/etc/apache2/sites-enabled/000-default':
        ensure => absent,
        before => Service[$::horizon::params::http_service],
      }

   # exec { 'a2enmod wsgi':
   #   command => 'a2enmod wsgi',
   #   path => ['/usr/bin','/usr/sbin','/bin/','/sbin'],
   #   require => Package["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"],
   #   before  => Package["$::horizon::params::package_name"],
   # }


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
