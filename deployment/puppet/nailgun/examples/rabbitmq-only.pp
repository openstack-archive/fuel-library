$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

#astute user
$rabbitmq_astute_user = $::fuel_settings['astute']['user']
$rabbitmq_astute_password = $::fuel_settings['astute']['password']

#mcollective user
$mco_user = $::fuel_settings['mcollective']['user']
$mco_password = $::fuel_settings['mcollective']['password']
$mco_vhost = "mcollective"
$stomp = false

$bind_ip = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$thread_pool_calc = min(100,max(12*$physicalprocessorcount,30))

class {'docker::container': }

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
  astute_user     => $rabbitmq_astute_user,
  astute_password => $rabbitmq_astute_password,
  bind_ip         => $bind_ip,
  mco_user        => $mco_user,
  mco_password    => $mco_password,
  mco_vhost       => $mco_vhost,
  stomp           => $stomp,
  env_config      => {
    'RABBITMQ_SERVER_ERL_ARGS' => "+K true +A${thread_pool_calc} +P 1048576",
    'ERL_EPMD_ADDRESS'         => $bind_ip,
    'NODENAME'                 => "rabbit@${::hostname}",
  },
}

