class glance::api(
  $log_verbose = 'false',
  $log_debug = 'false',
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

  file { "/etc/glance/glance-api.conf":
    ensure  => present,
    owner   => 'glance',
    group   => 'root',
    mode    => 640,
    content => template('glance/glance-api.conf.erb'),
    require => Class["glance"]
  }

  service { "glance-api":
    ensure     => running,
    enable     => true,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => File["/etc/glance/glance-api.conf"],
    require    => Class["glance"]
  }
}
