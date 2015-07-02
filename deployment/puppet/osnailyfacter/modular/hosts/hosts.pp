notice('MODULAR: hosts.pp')

resources { 'host':
  purge => true,
}

host { 'localhost' :
  ensure       => 'present',
  ip           => '127.0.0.1',
  host_aliases => 'localhost.localdomain',
}

host { 'ipv6-localhost' :
  ensure       => 'present',
  ip           => '::1',
  host_aliases => 'ip6-loopback',
}

class { "l23network::hosts_file":
  nodes => hiera('nodes'),
}
