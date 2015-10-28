class { 'Osnailyfacter::Resolvconf':
  management_vip => '192.168.0.6',
  name           => 'Osnailyfacter::Resolvconf',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'dpkg-reconfigure resolvconf':
  command     => '/usr/sbin/dpkg-reconfigure -f noninteractive resolvconf',
  refreshonly => 'true',
}

file { '/etc/default/resolvconf':
  content => 'REPORT_ABSENT_SYMLINK="yes"',
  path    => '/etc/default/resolvconf',
}

file { '/etc/resolv.conf':
  ensure => 'link',
  notify => 'Exec[dpkg-reconfigure resolvconf]',
  path   => '/etc/resolv.conf',
  target => '/run/resolvconf/resolv.conf',
}

file { '/etc/resolvconf/resolv.conf.d/head':
  ensure  => 'file',
  content => 'search pp
nameserver 192.168.0.6
',
  path    => '/etc/resolvconf/resolv.conf.d/head',
}

package { 'resolvconf':
  ensure => 'present',
  before => 'File[/etc/resolv.conf]',
  name   => 'resolvconf',
}

service { 'resolvconf':
  ensure    => 'running',
  enable    => 'true',
  name      => 'resolvconf',
  subscribe => ['File[/etc/resolvconf/resolv.conf.d/head]', 'File[/etc/default/resolvconf]'],
}

stage { 'main':
  name => 'main',
}

