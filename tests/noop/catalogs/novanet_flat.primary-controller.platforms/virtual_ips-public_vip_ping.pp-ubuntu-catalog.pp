class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cluster::virtual_ip_ping { 'vip__public':
  host_list => '10.108.1.1',
  name      => 'vip__public',
}

cs_resource { 'ping_vip__public':
  ensure          => 'present',
  before          => 'Cs_rsc_location[loc_ping_vip__public]',
  complex_type    => 'clone',
  name            => 'ping_vip__public',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '30'}},
  parameters      => {'dampen' => '30s', 'host_list' => '10.108.1.1', 'multiplier' => '1000', 'timeout' => '3s'},
  primitive_class => 'ocf',
  primitive_type  => 'ping',
  provided_by     => 'pacemaker',
}

cs_rsc_location { 'loc_ping_vip__public':
  before    => 'Service[ping_vip__public]',
  cib       => 'ping_vip__public',
  name      => 'loc_ping_vip__public',
  primitive => 'vip__public',
  rules     => {'boolean' => '', 'expressions' => [{'attribute' => 'not_defined', 'operation' => 'pingd', 'value' => 'or'}, {'attribute' => 'pingd', 'operation' => 'lte', 'value' => '0'}], 'score' => '-inf'},
}

service { 'ping_vip__public':
  ensure   => 'running',
  before   => 'Service[vip__public]',
  enable   => 'true',
  name     => 'ping_vip__public',
  provider => 'pacemaker',
}

service { 'vip__public':
  ensure   => 'running',
  enable   => 'true',
  name     => 'vip__public',
  provider => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

