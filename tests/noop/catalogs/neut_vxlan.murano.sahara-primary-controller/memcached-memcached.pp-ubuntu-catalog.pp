class { 'Memcached::Params':
  name => 'Memcached::Params',
}

class { 'Memcached':
  install_dev     => 'false',
  item_size       => 'false',
  listen_ip       => '192.168.0.2',
  lock_memory     => 'false',
  logfile         => '/var/log/memcached.log',
  manage_firewall => 'false',
  max_connections => '8192',
  max_memory      => '50%',
  name            => 'Memcached',
  package_ensure  => 'present',
  processorcount  => '4',
  service_restart => 'true',
  tcp_port        => '11211',
  udp_port        => '11211',
  user            => 'nobody',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

file { '/etc/memcached.conf':
  content => '# File managed by puppet

# Run memcached as a daemon.
-d

# pidfile
-P /var/run/memcached.pid

# Log memcached's output
logfile /var/log/memcached.log

# Use <num> MB memory max to use for object storage.
-m 16071


# IP to listen on
-l 192.168.0.2

# TCP port to listen on
-p 11211

# UDP port to listen on
-U 11211

# Run daemon as user
-u nobody

# Limit the number of simultaneous incoming connections.
-c 8192

# Number of threads to use to process incoming requests.
-t 4


',
  group   => 'root',
  mode    => '0644',
  notify  => 'Service[memcached]',
  owner   => 'root',
  path    => '/etc/memcached.conf',
  require => 'Package[memcached]',
}

package { 'memcached':
  ensure => 'present',
  name   => 'memcached',
}

service { 'memcached':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'false',
  name       => 'memcached',
}

stage { 'main':
  name => 'main',
}

