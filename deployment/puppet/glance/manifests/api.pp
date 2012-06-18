
#
# This class installs and configures the glance api server.
#
# == Paremeters:
#
#  $log_verbose - rather to log the glance api service at verbose level.
#  Optional. Default: false
#
#  $log_debug - rather to log the glance api service at debug level.
#  Optional. Default: false
#
#  $default_store - Backend used to store glance dist images.
#  Optional. Default: file
#
#  $bind_host - The address of the host to bind to.
#  Optional. Default: 0.0.0.0
#
#  $bind_port - The port the server should bind to.
#  Optional. Default: 9292
#
#  $registry_host - The address used to connecto to the registy service.
#  Optional. Default:
#
#  $registry_port - The port of the Glance registry service.
#  Optional. Default: 9191
#
#  $log_file - The path of file used for logging
#  Optional. Default: /var/log/glance/api.log
#
#
class glance::api(
  $log_verbose = 'False',
  $log_debug = 'False',
  $bind_host = '0.0.0.0',
  $bind_port = '9292',
  $backlog   = '4096',
  $workers   = '0',
  $log_file = '/var/log/glance/api.log',
  $registry_host = '0.0.0.0',
  $registry_port = '9191',
  $auth_type = 'keystone',
  $auth_host = '127.0.0.1',
  $auth_port = '35357',
  $auth_protocol = 'http',
  $auth_uri = "http://127.0.0.1:5000/",
  $keystone_tenant = 'admin',
  $keystone_user = 'admin',
  $keystone_password = 'ChangeMe',
  $enabled           = true
) inherits glance {

  # used to configure concat
  include 'concat::setup'
  require 'keystone::python'

  File {
    ensure  => present,
    owner   => 'glance',
    group   => 'root',
    mode    => '0640',
    notify  => Service['glance-api'],
    require => Class['glance'],
  }

  concat { '/etc/glance/glance-api.conf':
    owner   => 'glance',
    group   => 'root',
    mode    => 640,
    require => Class['glance'],
  }

  glance::api::config { 'header':
    config => {
      'log_verbose'   => $log_verbose,
      'log_debug'     => $log_debug,
      'bind_host'     => $bind_host,
      'bind_port'     => $bind_port,
      'log_file'      => $log_file,
      'backlog'       => $backlog,
      'workers'       => $workers,
      'registry_host' => $registry_host,
      'registry_port' => $registry_port
    },
    order  => '01',
  }

  glance::api::config { 'footer':
    config => {
      'auth_type' => $auth_type
    },
    order   => '99',
    require => Glance::Api::Config['backend'],
  }

  file { '/etc/glance/glance-api-paste.ini':
    content => template('glance/glance-api-paste.ini.erb'),
  }

  file { '/etc/glance/glance-cache.conf':
    content => template('glance/glance-cache.conf.erb'),
  }

  if $enabled {
    $service_ensure = 'running'
  } else {
    $service_ensure = 'stopped'
  }

  service { 'glance-api':
    name       => $::glance::params::api_service_name,
    ensure     => $service_ensure,
    enable     => $enabled,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => Concat['/etc/glance/glance-api.conf'],
  }
}
