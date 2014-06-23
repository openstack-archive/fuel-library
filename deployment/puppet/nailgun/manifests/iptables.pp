class nailgun::iptables (
$production            = 'docker',
$admin_iface           = 'eth0',
$ssh_port              = '22',
$nailgun_web_port      = '8000',
$nailgun_internal_port = '8001',
$nailgun_repo_port     = '8080',
$postgres_port         = '5432',
$ostf_port             = '8777',
$rsync_port            = '873',
$rsyslog_port          = '514',
$ntp_port              = '123',
$rabbitmq_ports        = ['4369','5672','15672','61613'],
$chain                 = 'INPUT',
)
{
  #Host services
  $network_address = ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'],$::fuel_settings['ADMIN_NETWORK']['netmask'])
  $network_cidr = ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask'])
  firewall { '004 forward_admin_net':
    chain      => 'POSTROUTING',
    table      => 'nat',
    source     => "${network_address}/${network_cidr}",
    outiface   => 'eth+',
    jump       => 'MASQUERADE',
  }
  sysctl::value{'net.ipv4.ip_forward': value=>'1'}

  firewall { '005 ssh':
    port   => $ssh_port,
    proto  => 'tcp',
    action => 'accept',
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
    port    => $rsync_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '040 rabbitmq_admin':
    chain   => $chain,
    port    => $rabbitmq_ports,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '041 rabbitmq_local':
    chain    => $chain,
    port     => $rabbitmq_ports,
    proto    => 'tcp',
    src_type => "LOCAL",
    action   => 'accept',
  }

  firewall { '042 rabbitmq_block_ext':
    chain   => $chain,
    port    => $rabbitmq_ports,
    proto   => 'tcp',
    action  => 'reject',
  }

  firewall {'999 iptables denied':
    chain      => 'INPUT',
    limit      => '5/min',
    jump       => 'LOG',
    log_prefix => 'iptables denied: ',
    log_level  => '7',
  }


}

