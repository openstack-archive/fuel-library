class { 'Cluster::Dns_ocf':
  name               => 'Cluster::Dns_ocf',
  primary_controller => 'true',
}

class { 'Osnailyfacter::Dnsmasq':
  before                 => 'Class[Cluster::Dns_ocf]',
  external_dns           => ['8.8.8.8', '8.8.4.4'],
  management_vrouter_vip => '10.108.2.3',
  master_ip              => '10.108.0.2',
  name                   => 'Osnailyfacter::Dnsmasq',
}

class { 'Settings':
  name => 'Settings',
}

class { 'main':
  name => 'main',
}

cs_resource { 'p_dns':
  ensure          => 'present',
  before          => 'Cs_rsc_colocation[dns-with-vrouter-ns]',
  complex_type    => 'clone',
  metadata        => {'failure-timeout' => '120', 'migration-threshold' => '3'},
  ms_metadata     => {'interleave' => 'true'},
  name            => 'p_dns',
  notify          => 'Service[p_dns]',
  operations      => {'monitor' => {'interval' => '20', 'timeout' => '10'}, 'start' => {'timeout' => '30'}, 'stop' => {'timeout' => '30'}},
  parameters      => {'ns' => 'vrouter'},
  primitive_class => 'ocf',
  primitive_type  => 'ns_dns',
  provided_by     => 'fuel',
}

cs_rsc_colocation { 'dns-with-vrouter-ns':
  ensure     => 'present',
  name       => 'dns-with-vrouter-ns',
  primitives => ['clone_p_dns', 'clone_p_vrouter'],
  score      => 'INFINITY',
}

file { '/etc/dnsmasq.d/dns.conf':
  ensure  => 'present',
  content => 'domain=pp
server=/pp/10.108.0.2
resolv-file=/etc/resolv.dnsmasq.conf
bind-interfaces
listen-address=10.108.2.3
',
  path    => '/etc/dnsmasq.d/dns.conf',
}

file { '/etc/dnsmasq.d':
  ensure => 'directory',
  path   => '/etc/dnsmasq.d',
}

file { '/etc/resolv.dnsmasq.conf':
  ensure  => 'present',
  before  => 'File[/etc/dnsmasq.d/dns.conf]',
  content => 'nameserver 8.8.8.8
nameserver 8.8.4.4
',
  path    => '/etc/resolv.dnsmasq.conf',
}

package { 'dnsmasq-base':
  ensure => 'present',
  name   => 'dnsmasq-base',
}

service { 'p_dns':
  ensure     => 'running',
  enable     => 'true',
  hasrestart => 'true',
  hasstatus  => 'true',
  name       => 'p_dns',
  provider   => 'pacemaker',
}

stage { 'main':
  name => 'main',
}

