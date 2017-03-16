class osnailyfacter::provision::distributed_base(
  $scheduler_enable = false,
  $scheduler_host   = 'localhost',
  $scheduler_port   = '8002',
  $user             = 'serializer'
  $group            = 'serializer'
  $worker_enable    = false,
  $worker_count     = undef,
  $worker_base_port = 35000,
  $worker_nice      = '19',
){
  $scheduler_node = "${scheduler_host}:${scheduler_port}"

  if $worker_count == undef {
    $max_workers = $::processorcount
  } else {
    $max_workers = $worker_count
  }

  ensure_resource('package', 'python-distributed')

  group { "$group":
    ensure  => present,
    require => Package["python-distributed"],
  }

  user { "$user":
    ensure  => present,
    gid     => $group,
    require => Group[$group]
  }

  if ($worker_enable == true) {
    $workers_range = range("1", $max_workers)

    osnailyfacter::provision::dsworker { $workers_range:
      base_port      => $worker_base_port,
      nice_level     => $nice_level,
      scheduler_node => $scheduler_node,
      user           => $user,
      group          => $group,
      require        => User[$user],
    }
  }

  if ($scheduler_enable == true) {
    osnailyfacter::provision::dsscheduler { 'distributed_scheduler':
      user           => $user,
      group          => $group,
      scheduler_host => $scheduler_host,
      scheduler_port => $scheduler_port,
      require        => User[$user],
    }
  }
}
