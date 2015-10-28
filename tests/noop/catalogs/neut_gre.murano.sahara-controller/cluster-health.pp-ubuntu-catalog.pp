class { 'Cluster::Sysinfo':
  disk_unit        => 'M',
  disks            => ['/', '/var/log', '/var/lib/glance', '/var/lib/mysql'],
  min_disk_free    => '100M',
  monitor_ensure   => 'present',
  monitor_interval => '30s',
  name             => 'Cluster::Sysinfo',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cs_property { 'node-health-strategy':
  ensure   => 'present',
  name     => 'node-health-strategy',
  provider => 'crm',
  value    => 'migrate-on-red',
}

cs_resource { 'sysinfo_node-129.test.domain.local':
  ensure          => 'present',
  name            => 'sysinfo_node-129.test.domain.local',
  operations      => {'monitor' => {'interval' => '30s'}},
  parameters      => {'disk_unit' => 'M', 'disks' => '/ /var/log /var/lib/glance /var/lib/mysql', 'min_disk_free' => '100M'},
  primitive_class => 'ocf',
  primitive_type  => 'SysInfo',
  provided_by     => 'pacemaker',
}

cs_rsc_location { 'sysinfo-on-node-129.test.domain.local':
  cib        => 'sysinfo_node-129.test.domain.local',
  name       => 'sysinfo-on-node-129.test.domain.local',
  node_name  => 'node-129.test.domain.local',
  node_score => 'INFINITY',
  primitive  => 'sysinfo_node-129.test.domain.local',
}

stage { 'main':
  name => 'main',
}

