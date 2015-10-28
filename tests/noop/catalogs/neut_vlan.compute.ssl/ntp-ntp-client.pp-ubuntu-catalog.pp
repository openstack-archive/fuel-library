anchor { 'ntp::begin':
  before => 'Class[Ntp::Install]',
  name   => 'ntp::begin',
}

anchor { 'ntp::end':
  name => 'ntp::end',
}

class { 'Ntp::Config':
  name   => 'Ntp::Config',
  notify => 'Class[Ntp::Service]',
}

class { 'Ntp::Install':
  before => 'Class[Ntp::Config]',
  name   => 'Ntp::Install',
}

class { 'Ntp::Params':
  name => 'Ntp::Params',
}

class { 'Ntp::Service':
  before => 'Anchor[ntp::end]',
  name   => 'Ntp::Service',
}

class { 'Ntp':
  autoupdate        => 'false',
  broadcastclient   => 'false',
  config            => '/etc/ntp.conf',
  config_template   => 'ntp/ntp.conf.erb',
  disable_auth      => 'false',
  disable_monitor   => 'true',
  driftfile         => '/var/lib/ntp/drift',
  fudge             => [],
  iburst_enable     => 'true',
  interfaces        => [],
  keys_controlkey   => '',
  keys_enable       => 'false',
  keys_file         => '/etc/ntp/keys',
  keys_requestkey   => '',
  keys_trusted      => [],
  minpoll           => '3',
  name              => 'Ntp',
  package_ensure    => 'present',
  package_manage    => 'true',
  package_name      => 'ntp',
  panic             => '0',
  peers             => [],
  preferred_servers => [],
  restrict          => ['-4 kod nomodify notrap nopeer noquery', '-6 default kod nomodify notrap nopeer noquery', '127.0.0.1', '::1'],
  servers           => '10.122.7.6',
  service_enable    => 'true',
  service_ensure    => 'running',
  service_manage    => 'true',
  service_name      => 'ntp',
  stepout           => '5',
  tinker            => 'true',
  udlc              => 'false',
  udlc_stratum      => '10',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

exec { 'remove_ntp_override':
  before  => ['Service[ntp]', 'Service[ntp]'],
  command => 'rm -f /etc/init/ntp.override',
  onlyif  => 'test -f /etc/init/ntp.override',
  path    => ['/sbin', '/bin', '/usr/bin', '/usr/sbin'],
}

file { '/etc/ntp.conf':
  ensure  => 'file',
  content => '# ntp.conf: Managed by puppet.
#
# Enable next tinker options:
# panic - keep ntpd from panicking in the event of a large clock skew
# when a VM guest is suspended and resumed;
# stepout - allow ntpd change offset faster
tinker panic 0 stepout 5

disable monitor

# Permit time synchronization with our time source, but do not
# permit the source to query or modify the service on this system.
restrict -4 kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1
restrict ::1



# Set up servers for ntpd with next options:
# server - IP address or DNS name of upstream NTP server
# iburst - allow send sync packages faster if upstream unavailable
# prefer - select preferrable server
# minpoll - set minimal update frequency
# maxpoll - set maximal update frequency
server 10.122.7.6 iburst minpoll 3


# Driftfile.
driftfile /var/lib/ntp/drift




',
  group   => '0',
  mode    => '0644',
  owner   => '0',
  path    => '/etc/ntp.conf',
}

file { 'create_ntp_override':
  ensure  => 'present',
  before  => ['Package[ntp]', 'Exec[remove_ntp_override]'],
  content => 'manual',
  group   => 'root',
  mode    => '0644',
  owner   => 'root',
  path    => '/etc/init/ntp.override',
}

package { 'ntp':
  ensure => 'present',
  before => 'Exec[remove_ntp_override]',
  name   => 'ntp',
}

service { 'ntp':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'ntp',
}

stage { 'main':
  name => 'main',
}

tweaks::ubuntu_service_override { 'ntpd':
  name         => 'ntpd',
  package_name => 'ntp',
  service_name => 'ntp',
}

