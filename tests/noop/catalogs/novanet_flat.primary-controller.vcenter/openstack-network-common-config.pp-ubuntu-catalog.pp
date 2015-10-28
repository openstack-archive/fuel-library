class { 'Settings':
  name => 'Settings',
}

class { 'Sysctl::Base':
  name => 'Sysctl::Base',
}

class { 'main':
  name => 'main',
}

file { '/etc/sysctl.conf':
  ensure => 'present',
  group  => '0',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/sysctl.conf',
}

stage { 'main':
  name => 'main',
}

sysctl::value { 'net.ipv4.ip_forward':
  key     => 'net.ipv4.ip_forward',
  name    => 'net.ipv4.ip_forward',
  require => 'Class[Sysctl::Base]',
  value   => '1',
}

sysctl::value { 'net.ipv4.neigh.default.gc_thresh1':
  key     => 'net.ipv4.neigh.default.gc_thresh1',
  name    => 'net.ipv4.neigh.default.gc_thresh1',
  require => 'Class[Sysctl::Base]',
  value   => '1024',
}

sysctl::value { 'net.ipv4.neigh.default.gc_thresh2':
  key     => 'net.ipv4.neigh.default.gc_thresh2',
  name    => 'net.ipv4.neigh.default.gc_thresh2',
  require => 'Class[Sysctl::Base]',
  value   => '2048',
}

sysctl::value { 'net.ipv4.neigh.default.gc_thresh3':
  key     => 'net.ipv4.neigh.default.gc_thresh3',
  name    => 'net.ipv4.neigh.default.gc_thresh3',
  require => 'Class[Sysctl::Base]',
  value   => '4096',
}

sysctl { 'net.ipv4.ip_forward':
  before => 'Sysctl_runtime[net.ipv4.ip_forward]',
  name   => 'net.ipv4.ip_forward',
  val    => '1',
}

sysctl { 'net.ipv4.neigh.default.gc_thresh1':
  before => 'Sysctl_runtime[net.ipv4.neigh.default.gc_thresh1]',
  name   => 'net.ipv4.neigh.default.gc_thresh1',
  val    => '1024',
}

sysctl { 'net.ipv4.neigh.default.gc_thresh2':
  before => 'Sysctl_runtime[net.ipv4.neigh.default.gc_thresh2]',
  name   => 'net.ipv4.neigh.default.gc_thresh2',
  val    => '2048',
}

sysctl { 'net.ipv4.neigh.default.gc_thresh3':
  before => 'Sysctl_runtime[net.ipv4.neigh.default.gc_thresh3]',
  name   => 'net.ipv4.neigh.default.gc_thresh3',
  val    => '4096',
}

sysctl_runtime { 'net.ipv4.ip_forward':
  name => 'net.ipv4.ip_forward',
  val  => '1',
}

sysctl_runtime { 'net.ipv4.neigh.default.gc_thresh1':
  name => 'net.ipv4.neigh.default.gc_thresh1',
  val  => '1024',
}

sysctl_runtime { 'net.ipv4.neigh.default.gc_thresh2':
  name => 'net.ipv4.neigh.default.gc_thresh2',
  val  => '2048',
}

sysctl_runtime { 'net.ipv4.neigh.default.gc_thresh3':
  name => 'net.ipv4.neigh.default.gc_thresh3',
  val  => '4096',
}

