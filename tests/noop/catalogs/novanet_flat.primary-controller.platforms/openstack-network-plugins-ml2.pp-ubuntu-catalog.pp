class { 'Neutron':
  name => 'Neutron',
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

