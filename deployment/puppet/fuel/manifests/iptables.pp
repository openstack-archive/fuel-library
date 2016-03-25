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

  firewallchain { 'INPUT:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
    purge  => true,
  }

  firewallchain { 'FORWARD:filter:IPv4':
    ensure => present,
    policy => drop,
    before => undef,
    purge  => true,
  }

  firewallchain { 'POSTROUTING:nat:IPv4':
    ensure => present,
    policy => accept,
    before => undef,
    purge  => true,
  }

  firewallchain { 'POSTROUTING:mangle:IPv4':
    ensure => present,
    policy => accept,
    before => undef,
    purge  => true,
  }

  firewall { '001 accept related established rules':
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  #Host services
  firewall { '002 forward_admin_net':
    chain    => 'POSTROUTING',
    table    => 'nat',
    proto    => 'all',
    source   => "${network_address}/${network_cidr}",
    outiface => 'e+',
    jump     => 'MASQUERADE',
  }
  sysctl::value{'net.ipv4.ip_forward': value=>'1'}

  firewall { '003 ssh':
    port   => $ssh_port,
    proto  => 'tcp',
    source => $ssh_network,
    action => 'accept',
  }

  firewall { '004 ntp':
    port    => $ntp_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '005 ntp_udp':
    port    => $ntp_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '006 snmp':
    port   => '162',
    proto  => 'udp',
    action => 'accept',
  }

  #Containerized services
  firewall { '007 nailgun_web':
    chain  => $chain,
    port   => $nailgun_web_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '008 nailgun_internal':
    chain   => $chain,
    port    => $nailgun_internal_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }
  firewall { '009 nailgun_internal_local':
    chain    => $chain,
    port     => $nailgun_internal_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
  }

  firewall { '010 nailgun_internal_block_ext':
    chain  => $chain,
    port   => $nailgun_internal_port,
    proto  => 'tcp',
    action => 'reject',
  }

  firewall { '011 postgres_local':
    chain    => $chain,
    port     => $postgres_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
  }

  firewall { '012 postgres':
    chain   => $chain,
    port    => $postgres_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '013 postgres_block_ext':
    chain  => $chain,
    port   => $postgres_port,
    proto  => 'tcp',
    action => 'reject',
  }

  firewall { '014 ostf_admin':
    chain   => $chain,
    port    => $ostf_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '015 ostf_local':
    chain    => $chain,
    port     => $ostf_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
  }

  firewall { '016 ostf_block_ext':
    chain  => $chain,
    port   => $ostf_port,
    proto  => 'tcp',
    action => 'reject',
  }

  firewall { '017 rsync':
    chain  => $chain,
    port   => $rsync_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '018 rsyslog':
    chain   => $chain,
    port    => $rsyslog_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '019 rsyslog':
    chain   => $chain,
    port    => $rsyslog_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '020 rabbitmq_admin_net':
    chain   => $chain,
    port    => $rabbitmq_ports,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }


  firewall { '021 rabbitmq_local':
    chain    => $chain,
    port     => concat($rabbitmq_ports, $rabbitmq_admin_port),
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
  }

  firewall { '022 rabbitmq_block_ext':
    chain  => $chain,
    port   => $rabbitmq_ports,
    proto  => 'tcp',
    action => 'reject',
  }

  firewall {'023 fuelweb_port':
    chain  => $chain,
    port   => $fuelweb_port,
    proto  => 'tcp',
    action => 'accept',
  }

  firewall { '024 keystone_admin':
    chain  => $chain,
    port   => $keystone_port,
    proto  => 'tcp',
    action => 'accept'
  }

  firewall { '025 keystone_admin_port admin_net':
    chain   => $chain,
    port    => $keystone_admin_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '026 nailgun_repo_admin':
    chain  => $chain,
    port   => $nailgun_repo_port,
    proto  => 'tcp',
    action => 'accept'
  }

  firewall { '027 forward admin_net':
    chain   => 'FORWARD',
    proto   => 'all',
    source  => "${network_address}/${network_cidr}",
    iniface => $admin_iface,
    action  => 'accept',
  }

  firewall { '028 forward admin_net conntrack':
    chain   => 'FORWARD',
    proto   => 'all',
    ctstate => ['ESTABLISHED', 'RELATED'],
    action  => 'accept'
  }

  firewall { '029 recalculate dhcp checksum':
    chain         => 'POSTROUTING',
    table         => 'mangle',
    proto         => 'udp',
    port          => 68,
    jump          => 'CHECKSUM',
    checksum_fill => true,
  }

  firewall { '030 allow loopback':
    chain   => 'INPUT',
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }

  firewall {'999 iptables denied':
    chain      => 'INPUT',
    limit      => '5/min',
    jump       => 'LOG',
    log_prefix => 'iptables denied: ',
    log_level  => '7',
  }
}
