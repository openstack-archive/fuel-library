class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-118.test.domain.local', 'internal_address' => '192.168.0.1', 'internal_netmask' => '255.255.255.0', 'name' => 'node-118', 'role' => 'cinder', 'storage_address' => '192.168.1.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '118', 'uid' => '118', 'user_node_name' => 'Untitled (1d:4b)'}, {'fqdn' => 'node-128.test.domain.local', 'internal_address' => '192.168.0.2', 'internal_netmask' => '255.255.255.0', 'name' => 'node-128', 'public_address' => '172.16.0.2', 'public_netmask' => '255.255.255.0', 'role' => 'compute', 'storage_address' => '192.168.1.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '128', 'uid' => '128', 'user_node_name' => 'Untitled (6f:9d)'}, {'fqdn' => 'node-128.test.domain.local', 'internal_address' => '192.168.0.2', 'internal_netmask' => '255.255.255.0', 'name' => 'node-128', 'public_address' => '172.16.0.2', 'public_netmask' => '255.255.255.0', 'role' => 'virt', 'storage_address' => '192.168.1.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '128', 'uid' => '128', 'user_node_name' => 'Untitled (6f:9d)'}, {'fqdn' => 'node-129.test.domain.local', 'internal_address' => '192.168.0.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-129', 'public_address' => '172.16.0.3', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '192.168.1.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '129', 'uid' => '129', 'user_node_name' => 'Untitled (74:27)'}, {'fqdn' => 'node-131.test.domain.local', 'internal_address' => '192.168.0.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-131', 'public_address' => '172.16.0.4', 'public_netmask' => '255.255.255.0', 'role' => 'controller', 'storage_address' => '192.168.1.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '131', 'uid' => '131', 'user_node_name' => 'Untitled (34:45)'}, {'fqdn' => 'node-132.test.domain.local', 'internal_address' => '192.168.0.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-132', 'role' => 'compute', 'storage_address' => '192.168.1.5', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '132', 'uid' => '132', 'user_node_name' => 'Untitled (18:c9)'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-118.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-118',
  ip           => '192.168.0.1',
  name         => 'node-118.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-128.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-128',
  ip           => '192.168.0.2',
  name         => 'node-128.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-129.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-129',
  ip           => '192.168.0.3',
  name         => 'node-129.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-131.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-131',
  ip           => '192.168.0.4',
  name         => 'node-131.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-132.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-132',
  ip           => '192.168.0.5',
  name         => 'node-132.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

