class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-1.domain.local', 'internal_address' => '10.122.12.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '10.122.11.4', 'public_netmask' => '255.255.255.0', 'role' => 'ceph-osd', 'storage_address' => '10.122.14.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'Untitled (2c:5e)'}, {'fqdn' => 'node-1.domain.local', 'internal_address' => '10.122.12.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '10.122.11.4', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '10.122.14.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'Untitled (2c:5e)'}, {'fqdn' => 'node-2.domain.local', 'internal_address' => '10.122.12.6', 'internal_netmask' => '255.255.255.0', 'name' => 'node-2', 'role' => 'compute', 'storage_address' => '10.122.14.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '2', 'uid' => '2', 'user_node_name' => 'Untitled (e5:e6)'}, {'fqdn' => 'node-3.domain.local', 'internal_address' => '10.122.12.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-3', 'role' => 'ceph-osd', 'storage_address' => '10.122.14.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '3', 'uid' => '3', 'user_node_name' => 'Untitled (50:1e)'}, {'fqdn' => 'node-4.domain.local', 'internal_address' => '10.122.12.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-4', 'role' => 'cinder', 'storage_address' => '10.122.14.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '4', 'uid' => '4', 'user_node_name' => 'Untitled (cb:23)'}],
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
  ip           => '10.122.12.3',
  name         => 'node-1.domain.local',
  target       => '/etc/hosts',
}

host { 'node-2.domain.local':
  ensure       => 'present',
  host_aliases => 'node-2',
  ip           => '10.122.12.6',
  name         => 'node-2.domain.local',
  target       => '/etc/hosts',
}

host { 'node-3.domain.local':
  ensure       => 'present',
  host_aliases => 'node-3',
  ip           => '10.122.12.4',
  name         => 'node-3.domain.local',
  target       => '/etc/hosts',
}

host { 'node-4.domain.local':
  ensure       => 'present',
  host_aliases => 'node-4',
  ip           => '10.122.12.5',
  name         => 'node-4.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

