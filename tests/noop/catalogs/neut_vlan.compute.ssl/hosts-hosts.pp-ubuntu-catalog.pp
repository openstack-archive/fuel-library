class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-1.domain.local', 'internal_address' => '10.122.7.1', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '10.122.6.2', 'public_netmask' => '255.255.255.0', 'role' => 'cinder', 'storage_address' => '10.122.9.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'Untitled (d8:bb)'}, {'fqdn' => 'node-1.domain.local', 'internal_address' => '10.122.7.1', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '10.122.6.2', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '10.122.9.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'Untitled (d8:bb)'}, {'fqdn' => 'node-2.domain.local', 'internal_address' => '10.122.7.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-2', 'public_address' => '10.122.6.4', 'public_netmask' => '255.255.255.0', 'role' => 'cinder', 'storage_address' => '10.122.9.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '2', 'uid' => '2', 'user_node_name' => 'Untitled (68:63)'}, {'fqdn' => 'node-2.domain.local', 'internal_address' => '10.122.7.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-2', 'public_address' => '10.122.6.4', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '10.122.9.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '2', 'uid' => '2', 'user_node_name' => 'Untitled (68:63)'}, {'fqdn' => 'node-3.domain.local', 'internal_address' => '10.122.7.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-3', 'public_address' => '10.122.6.3', 'public_netmask' => '255.255.255.0', 'role' => 'cinder', 'storage_address' => '10.122.9.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '3', 'uid' => '3', 'user_node_name' => 'Untitled (03:15)'}, {'fqdn' => 'node-3.domain.local', 'internal_address' => '10.122.7.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-3', 'public_address' => '10.122.6.3', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '10.122.9.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '3', 'uid' => '3', 'user_node_name' => 'Untitled (03:15)'}, {'fqdn' => 'node-4.domain.local', 'internal_address' => '10.122.7.2', 'internal_netmask' => '255.255.255.0', 'name' => 'node-4', 'role' => 'compute', 'storage_address' => '10.122.9.5', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '4', 'uid' => '4', 'user_node_name' => 'Untitled (a7:46)'}, {'fqdn' => 'node-5.domain.local', 'internal_address' => '10.122.7.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-5', 'role' => 'compute', 'storage_address' => '10.122.9.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '5', 'uid' => '5', 'user_node_name' => 'Untitled (2a:ee)'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-1.domain.local':
  ensure       => 'present',
  host_aliases => 'node-1',
  ip           => '10.122.7.1',
  name         => 'node-1.domain.local',
  target       => '/etc/hosts',
}

host { 'node-2.domain.local':
  ensure       => 'present',
  host_aliases => 'node-2',
  ip           => '10.122.7.4',
  name         => 'node-2.domain.local',
  target       => '/etc/hosts',
}

host { 'node-3.domain.local':
  ensure       => 'present',
  host_aliases => 'node-3',
  ip           => '10.122.7.5',
  name         => 'node-3.domain.local',
  target       => '/etc/hosts',
}

host { 'node-4.domain.local':
  ensure       => 'present',
  host_aliases => 'node-4',
  ip           => '10.122.7.2',
  name         => 'node-4.domain.local',
  target       => '/etc/hosts',
}

host { 'node-5.domain.local':
  ensure       => 'present',
  host_aliases => 'node-5',
  ip           => '10.122.7.3',
  name         => 'node-5.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

