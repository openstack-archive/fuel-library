notice('MODULAR: distributed_serialization_master.pp')

$network_data = hiera_hash('ADMIN_NETWORK')
$ipaddress    = $network_data['ipaddress']

anchor { 'begin': } ->

class { 'fuel::dsscheduler':
  scheduler_host => $ipaddress,
} ->

class { 'osnailyfacter::provision::distributed_serialization':
  scheduler_host => $ipaddress,
  nice_level     => '0',
} ->

anchor { 'end': }


