define osnailyfacter::provision::dsscheduler(
  $service_enabled = true,
  $user            = 'serializer',
  $group           = 'serializer',
  $scheduler_host  = 'localhost',
  $scheduler_port  = '8002',
){
  $systemd_base = '/etc/systemd/system'
  $service_name = "dsscheduler"

  file { "${systemd_base}/${service_name}.service":
    ensure  => present,
    content => template("osnailyfacter/${service_name}.service.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  } ->

  service { $service_name:
    ensure => $service_enabled,
    enable => $service_enabled,
  }
}
