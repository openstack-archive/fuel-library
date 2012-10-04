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
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $swift                 = false,
  $quantum               = false,
  $horizon_app_links     = false,
  $keystone_host         = '127.0.0.1',
  $keystone_port         = 5000,
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $django_debug          = 'False',
  $api_result_limit      = 1000
) {

  include horizon::params

  if $cache_server_ip =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['horizon']
  }

  package { ["$::horizon::params::http_service", "$::horizon::params::http_modwsgi", "$::horizon::params::package_name"]:
    ensure => present,
  }

  file { '/etc/openstack-dashboard/local_settings.py':
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
    require => Package["$::horizon::params::package_name"],
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
      }
    }

    'Debian': {
      exec { 'a2enmod wsgi':
        command => 'a2enmod wsgi',
        path => ['/usr/bin','/usr/sbin','/bin/','/sbin'],
        require => Package["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"],
        before  => Package["$::horizon::params::package_name"],
      }
    }
  }

  service { 'httpd':
    name      => $::horizon::params::http_service,
    ensure    => 'running',
    require   => [Package["$::horizon::params::http_service", "$::horizon::params::http_modwsgi"]],
    subscribe => File['/etc/openstack-dashboard/local_settings.py']
  }
}
