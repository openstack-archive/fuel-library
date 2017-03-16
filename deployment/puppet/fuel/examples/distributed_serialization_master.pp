notice('MODULAR: distributed_serialization_master.pp')

$network_data = hiera_hash('ADMIN_NETWORK')
$ipaddr       = $network_data['ipaddress']

anchor { 'begin': } ->

class { 'fuel::dsscheduler':
  scheduler_host => $ipaddr,
} ->

class { 'osnailyfacter::provision::distributed_serialization':
  scheduler_host => $ipaddr,
  nice_level     => '0',
} ->

anchor { 'end': }


