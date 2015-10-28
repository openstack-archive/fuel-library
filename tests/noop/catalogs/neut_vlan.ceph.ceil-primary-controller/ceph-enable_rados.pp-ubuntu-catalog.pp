class { 'Ceph::Params':
  name => 'Ceph::Params',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

package { 'ceph-deploy':
  ensure => 'installed',
  name   => 'ceph-deploy',
}

package { 'ceph':
  ensure => 'installed',
  name   => 'ceph',
}

service { 'radosgw':
  ensure   => 'running',
  enable   => 'true',
  name     => 'radosgw',
  provider => 'debian',
}

stage { 'main':
  name => 'main',
}

