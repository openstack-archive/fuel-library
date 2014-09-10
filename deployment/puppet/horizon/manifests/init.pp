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
# $django_debug         True/False. enable/disables debugging (debug level). defaults to false
# $django_verbose       True/False. enable/disables verbose logging (info level). defaults to false
# $log_level            Syslog level would be used for logging. If Verbose -> INFO, Debug -> DEBUG, otherwise -> the value given
# $api_result_limit     max number of Swift containers/objects to display on a single page
# $use_syslog           Redirect all apache logging to syslog. Required for FUEL-UI. Defaults to false.
#
class horizon(
  $secret_key,
  $bind_address          = '127.0.0.1',
  $cache_server_ip       = '127.0.0.1',
  $cache_server_port     = '11211',
  $swift                 = false,
  $quantum               = false,
  $package_ensure	       = present,
  $horizon_app_links     = false,
  $keystone_host         = '127.0.0.1',
  $keystone_port         = 5000,
  $keystone_scheme       = 'http',
  $keystone_default_role = 'Member',
  $django_debug          = false,
  $django_verbose        = false,
  $api_result_limit      = 1000,
  $http_port             = 80,
  $https_port            = 443,
  $use_ssl               = false,
  $log_level             = 'WARNING',
  $use_syslog            = false,
) {

  include horizon::params

  $root_url      = $::horizon::params::root_url
  $wsgi_user     = $::horizon::params::apache_user
  $wsgi_group    = $::horizon::params::apache_group

  package { [$::horizon::params::http_service,
             $::horizon::params::http_modwsgi]:
    ensure => present,
  }

  package { 'dashboard':
    name    => $::horizon::params::package_name,
    ensure  => $package_ensure,
    require => Package[$::horizon::params::http_service],
  }

  define horizon_safe_package(){
    if ! defined(Package[$name]){
      @package { $name : }
    }
  }

  File {
    require => Package['dashboard'],
    owner   => $wsgi_user,
    group   => $wsgi_group,
  }
  file { $::horizon::params::local_settings_path:
    content => template('horizon/local_settings.py.erb'),
    mode    => '0644',
  }

  $dashboard_directory = '/usr/share/openstack-dashboard/'

  file { $dashboard_directory :
    ensure => directory,
  }

  exec { 'chown_dashboard' :
    command     => "chown -R ${wsgi_user}:${wsgi_group} ${dashboard_directory}",
    path        => [ '/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
    refreshonly => true,
    provider    => 'shell',
  }

  Package['dashboard'] -> File[$dashboard_directory] ~> Exec['chown_dashboard']

  case $use_ssl {
    'exist': { # SSL certificate already exists
      $generate_sslcert_names = true
      $inject_certs = false
    }

    'custom': { # custom signed certificate
      $generate_sslcert_names = true
      $inject_certs = true
    }

    'default': { # use default package certificate
      $generate_sslcert_names = false
      $inject_certs = false
    }
  }

  if $generate_sslcert_names {
    $sslcert_pair = regsubst([$::horizon::params::ssl_cert_file,
                              $::horizon::params::ssl_key_file],
                        '(.+\/).+(\..+)', "\\1${::domain}\\2")

    $ssl_cert_file = $sslcert_pair[0]
    $ssl_key_file  = $sslcert_pair[1]
  } else {
    $ssl_cert_file = $::horizon::params::ssl_cert_file
    $ssl_key_file  = $::horizon::params::ssl_key_file
  }

  # inject signed certificate
  if $inject_certs {
    file { $ssl_cert_file:
      ensure  => present,
      mode    => '0644',
      owner   => 'root',
      group   => 'root',
      source  => "puppet:///ssl_certs/${::domain}.${::horizon::params::ssl_cert_type}",
    }

    file { $ssl_key_file:
      ensure  => present,
      mode    => '0640',
      owner   => 'root',
      group   => $::horizon::params::ssl_key_group,
      source  => "puppet:///ssl_certs/${::domain}.key",
    }
  }

  file { $horizon::params::logdir:
    ensure  => directory,
    mode    => '0750',
    owner   => $wsgi_user,
    group   => $wsgi_group,
  } ->
  file { "${horizon::params::logdir}/horizon.log":
    ensure  => present,
    mode    => '0640',
    owner   => $wsgi_user,
    group   => $wsgi_group,
  }
  Package["dashboard"] -> File[$horizon::params::logdir]
  File["${horizon::params::logdir}/horizon.log"] -> Service['httpd']

  file { $::horizon::params::vhosts_file:
    content => template('horizon/vhosts.erb'),
    mode    => '0644',
    require => Package['dashboard'],
    notify  => Service['httpd']
  }

  file { $::horizon::params::dashboard_http_conf_file:
    content => template('horizon/openstack-dashboard.conf.erb'),
    mode    => '0644',
    notify  => Service['httpd'],
    require => [
        Package['dashboard'],
        File[$::horizon::params::apache_confdir]
    ]
  }

  file { $::horizon::params::apache_tuning_file:
    content => template('horizon/zzz_performance_tuning.conf.erb'),
    mode    => '0644',
    notify  => Service['httpd'],
    require => [
        Package['dashboard'],
        File[$::horizon::params::apache_confdir]
    ]
  }

  file { 'httpd_listen_config_file':
    path    => $::horizon::params::httpd_listen_config_file,
    content => template('horizon/ports.conf.erb'),
    owner   => 'root',
    group   => 'root',
    notify  => Service['httpd'],
    before  => Package[$::horizon::params::http_service],
    require => File[$::horizon::params::apache_confdir]
  }

  file { $::horizon::params::apache_confdir:
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    require => []
  }

  case $::osfamily {
    'RedHat': {
      package { $::horizon::params::horizon_additional_packages : ensure => present }
      file { '/etc/httpd/conf.d/wsgi.conf':
        mode   => 644,
        owner  => root,
        group  => root,
        content => "LoadModule wsgi_module modules/mod_wsgi.so\n",
        require => Package[$::horizon::params::http_service,
                           $::horizon::params::http_modwsgi],
        before  => Package['dashboard'],
      }  # ensure there is a HTTP redirect from / to /dashboard

      if $use_ssl =~ /^(default|exist|custom)$/ {
        package { 'mod_ssl':
          ensure => present,
          before => Service['httpd'],
        }
      }

      file { '/etc/sysconfig/httpd':
        mode    => 0644,
        owner   => root,
        group   => root,
        content => template('horizon/redhat_sysconfig_httpd.erb'),
        require => Package[$::horizon::params::http_service],
        notify  => Service['httpd'],
      }

      augeas { 'remove_listen_directive':
        context => "/files/etc/httpd/conf/httpd.conf",
        changes => [
          "rm directive[. = 'Listen']"
        ],
        before  => Service['httpd'],
      }

      #todo: may be need fix
      Package['dashboard'] -> Exec['horizon_compress_styles']
      Package['dashboard'] ~> Exec['horizon_compress_styles']
      Package[$::horizon::params::horizon_additional_packages] -> Exec['horizon_compress_styles']
      exec { 'horizon_compress_styles':
        path    => '/bin:/usr/bin:/sbin:/usr/sbin',
        cwd     => '/usr/share/openstack-dashboard',
        command => 'python manage.py compress',
        refreshonly => true
      }
      Exec['horizon_compress_styles'] ~> Service['httpd']
    }
    'Debian': {
      A2mod {
        ensure  => present,
        require => Package[$::horizon::params::http_service],
        before  => Package['dashboard'],
        notify  => Service['httpd'],
      }

      a2mod { 'wsgi':
        require => Package[$::horizon::params::http_modwsgi]
      }

      if $use_ssl =~ /^(default|exist|custom)$/ {
        a2mod { ['rewrite', 'ssl']: }
      }

      file { '/etc/apache2/sites-enabled/openstack-dashboard':
        ensure  => link,
        target  => $::horizon::params::vhosts_file,
      }

      file { '/etc/apache2/sites-enabled/000-default':
        ensure => absent,
        before => Service['httpd'],
      }
    }
  }

  service { 'httpd':
    name      => $::horizon::params::http_service,
    ensure    => 'running',
    enable    => true
  }
  File[$::horizon::params::local_settings_path, $::horizon::params::logdir] ~> Service['httpd']
  Package[$::horizon::params::http_service, $::horizon::params::http_modwsgi] -> Service['httpd']
  Package<| title == $::horizon::params::http_service or title == $::horizon::params::http_modwsgi|> ~>
  Service<| title == 'httpd'|>
  if !defined(Service['httpd']) {
    notify{ "Module ${module_name} cannot notify service httpd on packages update": }
  }

  if $cache_server_ip =~ /^127\.0\.0\.1/ {
    Class['memcached'] -> Class['horizon']
  }
}
