class osnailyfacter::provision::distributed_serialization(
){
  notice('MODULAR: provision/distributed_serialization.pp')

  $master_ip = hiera('master_ip')

  class { 'osnailyfacter::provision::distributed_base':
    $scheduler_enable => false,
    $scheduler_host   => $master_ip,
    $worker_enable    => true,
  }
}
