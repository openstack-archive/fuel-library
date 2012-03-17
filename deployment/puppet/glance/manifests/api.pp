# = Class: glance::api
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
#  $filesystem_store_datadir - Location where dist images are stored when
#  default_store == file.
#  Optional. Default: /var/lib/glance/images/
#
#  $swift_store_auth_address - Optional. Default: '127.0.0.1:8080/v1.0/',
#
#  $swift_store_user - Optional. Default:'jdoe',
#
#  $swift_store_key - Optional. Default: 'a86850deb2742ec3cb41518e26aa2d89',
#
#  $swift_store_container - 'glance',
#
#  $swift_store_create_container_on_put - 'False'
#
class glance::api(
  $log_verbose = false,
  $log_debug = false,
  $default_store = 'file',
  $bind_host = '0.0.0.0',
  $bind_port = '9292',
  $registry_host = '0.0.0.0',
  $registry_port = '9191',
  $log_file = '/var/log/glance/api.log',
  $filesystem_store_datadir = '/var/lib/glance/images/',
  $swift_store_auth_address = '127.0.0.1:8080/v1.0/',
  $swift_store_user = 'jdoe',
  $swift_store_key = 'a86850deb2742ec3cb41518e26aa2d89',
  $swift_store_container = 'glance',
  $swift_store_create_container_on_put = 'False'
) inherits glance {

  file { '/etc/glance/glance-api.conf':
    ensure  => present,
    owner   => 'glance',
    group   => 'root',
    mode    => '0640',
    content => template('glance/glance-api.conf.erb'),
    require => Class['glance']
  }

  service { 'glance-api':
    name       => $::glance::params::api_service_name,
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File['/etc/glance/glance-api.conf'],
    require    => Class['glance']
  }
}
