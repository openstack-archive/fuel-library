class osnailyfacter::provision::distributed_serialization(
  $scheduler_host     = undef,
  $scheduler_port     = '8002',
  $worker_count       = undef,
  $worker_base_port   = 35000,
  $nice_level         = '19',
){
  notice('MODULAR: provision/distributed_serialization.pp')

  if $scheduler_host == undef {
    $master_ip      = hiera('master_ip')
    $scheduler_node = "${master_ip}:${scheduler_port}"
  } else {
    $scheduler_node = "${scheduler_host}:${scheduler_port}"
  }

  if $worker_count == undef {
    $max_workers = $::processorcount
  } else {
    $max_workers = $worker_count
  }

  $user = 'serializer'

  package {'python-distributed':
    ensure => installed,
  } ->

  group { "$user":
    ensure => present,
    name   => $title,
  }

  user { "$user":
    ensure  => present,
    name    => $title,
    gid     => $user,
    require => Group[$user]
  }

  $workers_range = range("1", $max_workers)

  osnailyfacter::provision::dsworker { $workers_range:
    base_port      => $worker_base_port,
    scheduler_node => $scheduler_node,
    nice_level     => $nice_level,
    user           => $user,
    group          => $user,
    require        => User[$user],
  }
}
