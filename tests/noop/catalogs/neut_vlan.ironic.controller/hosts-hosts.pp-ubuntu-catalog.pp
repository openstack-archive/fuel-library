class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-1.test.domain.local', 'internal_address' => '192.168.0.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-1', 'public_address' => '172.16.51.117', 'public_netmask' => '255.255.255.240', 'role' => 'primary-controller', 'storage_address' => '192.168.1.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '1', 'uid' => '1', 'user_node_name' => 'Untitled (cc:a5)'}, {'fqdn' => 'node-2.test.domain.local', 'internal_address' => '192.168.0.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-2', 'role' => 'ironic', 'storage_address' => '192.168.1.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '2', 'uid' => '2', 'user_node_name' => 'Untitled (6c:19)'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-1.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-1',
  ip           => '192.168.0.3',
  name         => 'node-1.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-2.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-2',
  ip           => '192.168.0.4',
  name         => 'node-2.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

