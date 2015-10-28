class { 'L23network::Hosts_file':
  hosts_file => '/etc/hosts',
  name       => 'L23network::Hosts_file',
  nodes      => [{'fqdn' => 'node-121.test.domain.local', 'internal_address' => '192.168.0.1', 'internal_netmask' => '255.255.255.0', 'name' => 'node-121', 'role' => 'primary-mongo', 'storage_address' => '192.168.1.1', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '121', 'uid' => '121', 'user_node_name' => 'Untitled (18:c9)'}, {'fqdn' => 'node-124.test.domain.local', 'internal_address' => '192.168.0.2', 'internal_netmask' => '255.255.255.0', 'name' => 'node-124', 'role' => 'ceph-osd', 'storage_address' => '192.168.1.2', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '124', 'uid' => '124', 'user_node_name' => 'Untitled (6f:9d)'}, {'fqdn' => 'node-125.test.domain.local', 'internal_address' => '192.168.0.3', 'internal_netmask' => '255.255.255.0', 'name' => 'node-125', 'public_address' => '172.16.0.2', 'public_netmask' => '255.255.255.0', 'role' => 'primary-controller', 'storage_address' => '192.168.1.3', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '125', 'uid' => '125', 'user_node_name' => 'Untitled (34:45)'}, {'fqdn' => 'node-126.test.domain.local', 'internal_address' => '192.168.0.4', 'internal_netmask' => '255.255.255.0', 'name' => 'node-126', 'role' => 'ceph-osd', 'storage_address' => '192.168.1.4', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '126', 'uid' => '126', 'user_node_name' => 'Untitled (12:ea)'}, {'fqdn' => 'node-127.test.domain.local', 'internal_address' => '192.168.0.5', 'internal_netmask' => '255.255.255.0', 'name' => 'node-127', 'role' => 'compute', 'storage_address' => '192.168.1.5', 'storage_netmask' => '255.255.255.0', 'swift_zone' => '127', 'uid' => '127', 'user_node_name' => 'Untitled (74:27)'}],
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

host { 'node-121.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-121',
  ip           => '192.168.0.1',
  name         => 'node-121.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-124.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-124',
  ip           => '192.168.0.2',
  name         => 'node-124.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-125.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-125',
  ip           => '192.168.0.3',
  name         => 'node-125.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-126.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-126',
  ip           => '192.168.0.4',
  name         => 'node-126.test.domain.local',
  target       => '/etc/hosts',
}

host { 'node-127.test.domain.local':
  ensure       => 'present',
  host_aliases => 'node-127',
  ip           => '192.168.0.5',
  name         => 'node-127.test.domain.local',
  target       => '/etc/hosts',
}

stage { 'main':
  name => 'main',
}

