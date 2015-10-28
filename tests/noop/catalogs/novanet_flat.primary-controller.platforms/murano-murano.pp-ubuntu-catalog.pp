class { 'Openstack::Firewall':
  name => 'Openstack::Firewall',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

stage { 'main':
  name => 'main',
}

