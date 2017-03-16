define osnailyfacter::provision::dsworker(
  $base_port      = 35000,
  $enabled        = true,
  $nice_level     = '19',
  $scheduler_node = undef,
  $user           = 'serializer',
  $group          = 'serializer',
) {
  if !is_bool($enabled) {
    fail('"enabled" variable value must be boolean')
  }

  if !is_integer($name) {
    fail("Distributed serialization worker name should be an integer, not ${name}")
  }

  if $scheduler_node == undef {
    fail("Scheduler node not defined for distributed serialization worker ${name}")
  }

  $port_number  = $base_port + $name
  $systemd_base = '/etc/systemd/system'
  $service_name = "dsworker-${port_number}"

  file { "${systemd_base}/${service_name}.service":
    ensure  => present,
    content => template('osnailyfacter/dsworker.service.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  } ->

  service { $service_name:
    ensure => $enabled,
    enable => $enabled,
  }
}
