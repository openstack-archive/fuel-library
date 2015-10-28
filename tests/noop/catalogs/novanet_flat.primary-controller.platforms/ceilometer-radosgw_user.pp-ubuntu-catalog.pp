ceilometer_radosgw_user { 'ceilometer':
  caps   => {'buckets' => 'read', 'usage' => 'read'},
  name   => 'ceilometer',
  notify => 'Service[ceilometer-agent-central]',
}

class { 'Ceilometer::Params':
  name => 'Ceilometer::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

service { 'ceilometer-agent-central':
  ensure   => 'running',
  enable   => 'true',
  name     => 'ceilometer-agent-central',
  provider => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

