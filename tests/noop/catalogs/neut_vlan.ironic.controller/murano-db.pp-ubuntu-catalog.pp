class { 'Murano::Api':
  name => 'Murano::Api',
}

class { 'Mysql::Config':
  name => 'Mysql::Config',
}

class { 'Mysql::Server':
  name => 'Mysql::Server',
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

