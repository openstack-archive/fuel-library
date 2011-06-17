class glance::registry(
  $verbose = 'true',
  $debug = 'true',
  $bind_host = '0.0.0.0',
  $bind_port = '9191',
  $log_file = '/var/log/glance/registry.log',
  $sql_connection = 'sqlite:///var/lib/glance/glance.sqlite',
  $sql_idle_timeout = '3600'
) inherits glance {
  file { "/etc/glance/glance-registry.conf":
    ensure  => present,
    owner   => 'glance',
    group   => 'root',
    mode    => 640,
    content => template('glance/glance-registry.conf.erb'),
    require => Class["glance"]
  }
  service { "glance-registry":
    ensure    => running,
    enable    => true,
    subscribe => File["/etc/glance/glance-registry.conf"],
    require   => Class["glance"]
  }

}
