class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

file { '/etc/pki/tls/certs/public_haproxy.pem':
  ensure  => 'present',
  content => 'somedataboutyourkeypair',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/pki/tls/certs/public_haproxy.pem',
}

file { '/etc/pki/tls/certs':
  ensure => 'directory',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/pki/tls/certs',
}

file { '/etc/pki/tls':
  ensure => 'directory',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/pki/tls',
}

file { '/etc/pki':
  ensure => 'directory',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/etc/pki',
}

file { '/var/lib/astute/haproxy/public_haproxy.pem':
  ensure  => 'present',
  content => 'somedataboutyourkeypair',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/var/lib/astute/haproxy/public_haproxy.pem',
}

file { '/var/lib/astute/haproxy':
  ensure => 'directory',
  group  => 'root',
  mode   => '0644',
  owner  => 'root',
  path   => '/var/lib/astute/haproxy',
}

stage { 'main':
  name => 'main',
}

