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
)
{
  case $production {
    /docker/: {
      $chain = 'FORWARD'
    }
    default: {
      $chain = 'INPUT'
    }
  }
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

  firewall { '007 snmp':
    port   => '162',
    proto  => 'udp',
    action => 'accept',
  }

  #Containerized services
  firewall { '010 nailgun_web':
    chain  => $chain,
    port   => $nailgun_web_port,
    proto  => 'tcp',
    action => 'accept',
  }
  firewall { '011 nailgun_internal':
    chain   => $chain,
    port    => $nailgun_internal_port,
    proto   => 'tcp',
    iniface => 'docker0',
    action  => 'accept',
  }
  firewall { '012 nailgun_internal_block_ext':
    chain   => $chain,
    port    => $nailgun_internal_port,
    proto   => 'tcp',
    action  => 'drop',
  }
  firewall { '013 postgres':
    chain   => $chain,
    port    => $postgres_port,
    proto   => 'tcp',
    iniface => 'docker0',
    action  => 'accept',
  }
  firewall { '014 postgres_block_ext':
    chain   => $chain,
    port    => $postgres_port,
    proto   => 'tcp',
    action  => 'drop',
  }
  firewall { '020 ostf_admin':
    chain   => $chain,
    port    => $ostf_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }
  firewall { '021 ostf_block_ext':
    chain   => $chain,
    port    => $ostf_port,
    proto   => 'tcp',
    action  => 'drop',
  }
  firewall { '022 rsync':
    chain   => $chain,
    port    => $rsync_port,
    proto   => 'tcp',
    action  => 'accept',
  }
  firewall { '023 rsyslog':
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

  firewall { '041 rabbitmq_block_ext':
    chain   => $chain,
    port    => $rabbitmq_ports,
    proto   => 'tcp',
    action  => 'drop',
  }

  firewall {'999 iptables denied':
    chain      => 'INPUT',
    limit      => '5/min',
    jump       => 'LOG',
    log_prefix => 'iptables denied: ',
    log_level  => '7',
  }

##Deprecated iptables start
  define access_to_nailgun_port($port, $protocol='tcp') {
    $rule = "-p $protocol -m state --state NEW -m $protocol --dport $port -j ACCEPT"
    exec { "access_to_nailgun_${protocol}_port: $port":
      command => "iptables -t filter -I INPUT 1 $rule; \
      /etc/init.d/iptables save",
      unless => "iptables -t filter -S INPUT | grep -q \"^-A INPUT $rule\""
    }
  }

  define ip_forward($network) {
    $rule = "-s $network ! -o docker0 -j MASQUERADE"
    exec { "ip_forward: $network":
      command => "iptables -t nat -I POSTROUTING 1 $rule; \
      /etc/init.d/iptables save",
      unless => "iptables -t nat -S POSTROUTING | grep -q \"^-A POSTROUTING $rule\""
    }
  }

  #access_to_nailgun_port { "nailgun_web":    port => '8000' }
  #access_to_nailgun_port { "nailgun_repo":    port => '8080' }
  #$network_address = ipcalc_network_by_address_netmask($::fuel_settings['ADMIN_NETWORK']['ipaddress'],$::fuel_settings['ADMIN_NETWORK']['netmask'])
  #$network_cidr = ipcalc_network_cidr_by_netmask($::fuel_settings['ADMIN_NETWORK']['netmask'])
  #ip_forward {'forward_slaves': network => "${network_address}/${network_cidr}"}
##Deprecated iptables end



}
