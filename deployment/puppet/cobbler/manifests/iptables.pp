class cobbler::iptables (
$chain = 'INPUT',
$interface,
$source,
) {

  Firewall {
    chain   => $chain,
    action  => 'accept',
    source  => $source,
    iniface => $interface,
  }

  case $::operatingsystem {
    /(?i)(debian|ubuntu)/:{
      file { '/etc/network/if-post-down.d/iptablessave':
        content => template('cobbler/ubuntu/iptablessave.erb'),
        owner   => root,
        group   => root,
        mode    => '0755',
      }
      file { '/etc/network/if-pre-up.d/iptablesload':
        content => template('cobbler/ubuntu/iptablesload.erb'),
        owner   => root,
        group   => root,
        mode    => '0755',
      }
    }
  }
  firewall { '101 dns_tcp':
    port   => '53',
    proto  => 'tcp',
  }
  firewall { '102 dns_udp':
    port   => '53',
    proto  => 'udp',
  }
  firewall { '103 dhcp':
    port   => ['67','68'],
    proto  => 'udp',
  }
  firewall { '104 tftp':
    port   => '69',
    proto  => 'udp',
  }
  firewall { '111 cobbler_web':
    port   => ['80','443'],
    proto  => 'tcp',
  }
}
