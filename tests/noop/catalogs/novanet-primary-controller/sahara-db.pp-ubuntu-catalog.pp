class { 'Mysql::Config':
  name => 'Mysql::Config',
}

class { 'Mysql::Server':
  name => 'Mysql::Server',
}

class { 'Sahara::Api':
  name => 'Sahara::Api',
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

