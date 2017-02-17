class provision::iptables {

  firewall { '101 dns_tcp':
    chain  => INPUT,
    dport  => '53',
    proto  => 'tcp',
    action => 'accept',
  }
  firewall { '102 dns_udp':
    chain  => INPUT,
    dport  => '53',
    proto  => 'udp',
    action => 'accept',
  }
  firewall { '103 dhcp':
    chain  => INPUT,
    dport  => ['67','68'],
    proto  => 'udp',
    action => 'accept',
  }
  firewall { '104 tftp':
    chain  => INPUT,
    dport  => '69',
    proto  => 'udp',
    action => 'accept',
  }

}
