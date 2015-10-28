class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-135.test.domain.local', 'internal_address' => '192.168.0.2', 'internal_netmask' => '255.255.255.0', 'name' => 'node-135', 'public_address' => '172.16.0.3', 'public_netmask' => '255.255.255.0', 'role' => 'cinder', 'storage_address' => '192.168.1.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '135', 'uid' => '135', 'user_node_name' => 'Untitled (18:c9)'}, {'fqdn' => 'node-136.test.domain.local', 'internal_address' => '192.168.0.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-136', 'public_address' => '172.16.0.4', 'public_netmask' => '255.255.255.0', 'role' => 'compute', 'storage_address' => '192.168.1.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '136', 'uid' => '136', 'user_node_name' => 'Untitled (1d:4b)'}, {'fqdn' => 'node-137.test.domain.local', 'internal_address' => '192.168.0.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-137', 'public_address' => '172.16.0.5', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '192.168.1.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '137', 'uid' => '137', 'user_node_name' => 'Untitled (34:45)'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-135.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-135',
  ip           => '192.168.0.2',
  name         => 'node-135.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-136.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-136',
  ip           => '192.168.0.3',
  name         => 'node-136.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-137.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-137',
  ip           => '192.168.0.4',
  name         => 'node-137.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

