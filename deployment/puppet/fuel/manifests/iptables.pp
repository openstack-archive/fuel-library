class fuel::iptables (
  $network_address,
  $network_cidr,

  $admin_iface           = $::fuel::params::admin_interface,
  $ssh_port              = '22',
  $ssh_network           = '0.0.0.0/0',
  $nailgun_web_port      = $::fuel::params::nailgun_port,
  $nailgun_internal_port = $::fuel::params::nailgun_internal_port,
  $nailgun_repo_port     = $::fuel::params::repo_port,
  $postgres_port         = $::fuel::params::db_port,
  $ostf_port             = $::fuel::params::ostf_port,
  $rsync_port            = '873',
  $rsyslog_port          = '514',
  $ntp_port              = '123',
  $rabbitmq_ports        = ['4369','5672','61613'],
  $rabbitmq_admin_port   = '15672',
  $fuelweb_port          = $::fuel::params::nailgun_ssl_port,
  $keystone_port         = $::fuel::params::keystone_port,
  $keystone_admin_port   = $::fuel::params::keystone_admin_port,
  $chain                 = 'INPUT',
  ) inherits fuel::params {

  #Enable cobbler's iptables rules even if Cobbler not called
  include cobbler::iptables

  firewall { '002 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  } ->

  #Host services
  firewall { '004 forward_admin_net':
    chain      => 'POSTROUTING',
    table      => 'nat',
    proto      => 'all',
    source     => "${network_address}/${network_cidr}",
    outiface   => 'e+',
    jump       => 'MASQUERADE',
  }
  sysctl::value{'net.ipv4.ip_forward': value=>'1'}

  firewall { '003 ssh: new pipe for a sessions':
    proto  => 'tcp',
    dport  => $ssh_port,
    state  => 'NEW',
    recent => 'set',
  }

  firewall { '004 ssh: block more than 3 conn/min':
    proto     => 'tcp',
    dport     => $ssh_port,
    state     => 'NEW',
    recent    => 'update',
    rseconds  => 60,
    rhitcount => 4,
    action    => 'drop',
  }

  firewall { '005 ssh: restrict on network':
    proto   => 'tcp',
    dport   => $ssh_port,
    source  => $ssh_network,
    action  => 'accept',
  }

  firewall { '006 ntp':
    port    => $ntp_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '007 ntp_udp':
    port    => $ntp_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '008 snmp':
    port   => '162',
    proto  => 'udp',
    action => 'accept',
  }

  #Containerized services
  firewall { '009 nailgun_web':
    chain  => $chain,
    port   => $nailgun_web_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '010 nailgun_internal':
    chain   => $chain,
    port    => $nailgun_internal_port,
    proto   => 'tcp',
    iniface => 'docker0',
    action  => 'accept',
  }
  firewall { '011 nailgun_internal_local':
    chain    => $chain,
    port     => $nailgun_internal_port,
    proto    => 'tcp',
    src_type => "LOCAL",
    action   => 'accept',
  }

  firewall { '012 nailgun_internal_block_ext':
    chain   => $chain,
    port    => $nailgun_internal_port,
    proto   => 'tcp',
    action  => 'reject',
  }

  firewall { '013 postgres_local':
    chain    => $chain,
    port     => $postgres_port,
    proto    => 'tcp',
    src_type => "LOCAL",
    action   => 'accept',
  }

  firewall { '014 postgres':
    chain    => $chain,
    port     => $postgres_port,
    proto    => 'tcp',
    iniface  => 'docker0',
    action   => 'accept',
  }

  firewall { '015 postgres_block_ext':
    chain   => $chain,
    port    => $postgres_port,
    proto   => 'tcp',
    action  => 'reject',
  }

  firewall { '020 ostf_admin':
    chain   => $chain,
    port    => $ostf_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '021 ostf_local':
    chain    => $chain,
    port     => $ostf_port,
    proto    => 'tcp',
    src_type => "LOCAL",
    action   => 'accept',
  }

  firewall { '022 ostf_block_ext':
    chain   => $chain,
    port    => $ostf_port,
    proto   => 'tcp',
    action  => 'reject',
  }

  firewall { '023 rsync':
    chain   => $chain,
    port    => $rsync_port,
    proto   => 'tcp',
    action  => 'accept',
  }

  firewall { '024 rsyslog':
    chain   => $chain,
    port    => $rsyslog_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '025 rsyslog':
    chain   => $chain,
    port    => $rsyslog_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '040 rabbitmq_admin_net':
    chain   => $chain,
    port    => $rabbitmq_ports,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }


  firewall { '041 rabbitmq_local':
    chain    => $chain,
    port     => concat($rabbitmq_ports, $rabbitmq_admin_port),
    proto    => 'tcp',
    src_type => "LOCAL",
    action   => 'accept',
  }

  firewall { '042 rabbitmq_block_ext':
    chain    => $chain,
    port     => $rabbitmq_ports,
    proto    => 'tcp',
    action   => 'reject',
  }

  firewall {'043 fuelweb_port':
    chain    => $chain,
    port     => $fuelweb_port,
    proto    => 'tcp',
    action   => 'accept',
  }

  firewall { '046 keystone_admin':
    chain    => $chain,
    port     => $keystone_port,
    proto    => 'tcp',
    action   => 'accept'
  }

  firewall { '047 keystone_admin_port admin_net':
    chain    => $chain,
    port     => $keystone_admin_port,
    proto    => 'tcp',
    iniface  => $admin_iface,
    action   => 'accept',
  }

  firewall { '049 nailgun_repo_admin':
    chain    => $chain,
    port     => $nailgun_repo_port,
    proto    => 'tcp',
    action   => 'accept'
  }

  firewall { '050 forward admin_net':
    chain    => 'FORWARD',
    proto    => 'all',
    source   => "${network_address}/${network_cidr}",
    iniface  => $admin_iface,
    action   => 'accept',
  }

  firewall { '051 forward admin_net conntrack':
    chain    => 'FORWARD',
    proto    => 'all',
    ctstate  => ['ESTABLISHED', 'RELATED'],
    action   => 'accept'
  }

  firewall {'999 iptables denied':
    chain      => 'INPUT',
    limit      => '5/min',
    jump       => 'LOG',
    log_prefix => 'iptables denied: ',
    log_level  => '7',
  }


}
