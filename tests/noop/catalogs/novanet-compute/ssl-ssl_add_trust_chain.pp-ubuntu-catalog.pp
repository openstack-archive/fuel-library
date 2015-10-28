class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'add_trust':
  command => 'update-ca-certificates',
  path    => '/bin:/usr/bin:/sbin:/usr/sbin',
}

file { '/usr/local/share/ca-certificates/public_haproxy.crt':
  ensure => 'link',
  before => 'Exec[add_trust]',
  path   => '/usr/local/share/ca-certificates/public_haproxy.crt',
  target => '/etc/pki/tls/certs/public_haproxy.pem',
}

host { 'public.fuel.local':
  ensure => 'present',
  ip     => '172.16.0.6',
  name   => 'public.fuel.local',
}

stage { 'main':
  name => 'main',
}

