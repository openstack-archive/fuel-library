notice('MODULAR: distributed_serialization_master.pp')

$network_data = hiera_hash('ADMIN_NETWORK')
$ipaddr       = $network_data['ipaddress']

class { 'osnailyfacter::provision::distributed_base':
  scheduler_enable => true,
  scheduler_host   => $ipaddr,
  worker_enable    => true,
  worker_nice      => '0',
}
