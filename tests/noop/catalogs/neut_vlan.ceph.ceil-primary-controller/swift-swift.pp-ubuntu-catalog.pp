class { 'Ceilometer':
  name => 'Ceilometer',
}

class { 'Memcached':
  name => 'Memcached',
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

