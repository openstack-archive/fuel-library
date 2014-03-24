$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'dev'
}


#astute user
$rabbitmq_astute_user = "naily"
$rabbitmq_astute_password = "naily"

#mcollective user
$mco_user = "mcollective"
$mco_password = "marionette"
$mco_vhost = "mcollective"
$stomp = false


user { "rabbitmq":
  ensure => present,
  managehome => true,
  uid        => 495,
  shell      => '/bin/bash',
  home       => '/var/lib/rabbitmq',
  comment    => 'RabbitMQ messaging server',
}

file { "/var/log/rabbitmq":
  ensure  => directory,
  owner   => 'rabbitmq',
  group   => 'rabbitmq',
  mode    => 0755,
  require => User['rabbitmq'],
  before  => Service["rabbitmq-server"],
}

class { 'nailgun::rabbitmq':
  production      => $production,
  astute_password => $rabbitmq_astute_user,
  astute_user     => $rabbitmq_astute_password,
  mco_user        => $mco_user,
  mco_password    => $mco_password,
  mco_vhost       => $mco_vhost,
  stomp           => $stomp,
}

