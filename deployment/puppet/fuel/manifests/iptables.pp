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

  # Chains for externally defined rules (not managed by Puppet)

  firewallchain { 'ext-filter-input:filter:IPv4':
    ensure => present,
    before => undef,
    purge  => false,
  }

  firewallchain { 'ext-filter-forward:filter:IPv4':
    ensure => present,
    before => undef,
    purge  => false,
  }

  firewallchain { 'ext-nat-postrouting:nat:IPv4':
    ensure => present,
    before => undef,
    purge  => false,
  }

  firewallchain { 'ext-mangle-postrouting:mangle:IPv4':
    ensure => present,
    before => undef,
    purge  => false,
  }

  ## INPUT:filter:IPv4

  firewall { '001 ssh':
    chain  => $chain,
    table  => 'filter',
    port   => $ssh_port,
    proto  => 'tcp',
    source => $ssh_network,
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '002 ntp':
    chain   => $chain,
    table   => 'filter',
    port    => $ntp_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '003 ntp_udp':
    chain   => $chain,
    table   => 'filter',
    port    => $ntp_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '004 snmp':
    chain  => $chain,
    table  => 'filter',
    port   => '162',
    proto  => 'udp',
    action => 'accept',
    state  => ['NEW'],
  }

  #Containerized services
  firewall { '005 nailgun_web':
    chain  => $chain,
    table  => 'filter',
    port   => $nailgun_web_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '006 nailgun_internal':
    chain   => $chain,
    table   => 'filter',
    port    => $nailgun_internal_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '007 nailgun_internal_block_ext':
    chain  => $chain,
    table  => 'filter',
    port   => $nailgun_internal_port,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '008 postgres_local':
    chain    => $chain,
    table    => 'filter',
    port     => $postgres_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
    state    => ['NEW'],
  }

  firewall { '009 postgres':
    chain   => $chain,
    table   => 'filter',
    port    => $postgres_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '010 postgres_block_ext':
    chain  => $chain,
    table  => 'filter',
    port   => $postgres_port,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '011 ostf_admin':
    chain   => $chain,
    table   => 'filter',
    port    => $ostf_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '012 ostf_local':
    chain    => $chain,
    table    => 'filter',
    port     => $ostf_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
    state    => ['NEW'],
  }

  firewall { '013 ostf_block_ext':
    chain  => $chain,
    table  => 'filter',
    port   => $ostf_port,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '014 rsync':
    chain  => $chain,
    table  => 'filter',
    port   => $rsync_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '015 rsyslog':
    chain   => $chain,
    table   => 'filter',
    port    => $rsyslog_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '016 rsyslog':
    chain   => $chain,
    table   => 'filter',
    port    => $rsyslog_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '017 rabbitmq_admin_net':
    chain   => $chain,
    table   => 'filter',
    port    => $rabbitmq_ports,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '018 rabbitmq_local':
    chain    => $chain,
    table    => 'filter',
    port     => concat($rabbitmq_ports, $rabbitmq_admin_port),
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
    state    => ['NEW'],
  }

  firewall { '019 rabbitmq_block_ext':
    chain  => $chain,
    table  => 'filter',
    port   => $rabbitmq_ports,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall {'020 fuelweb_port':
    chain  => $chain,
    table  => 'filter',
    port   => $fuelweb_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '021 keystone_admin':
    chain  => $chain,
    table  => 'filter',
    port   => $keystone_port,
    proto  => 'tcp',
    action => 'accept'
    state  => ['NEW'],
  }

  firewall { '022 keystone_admin_port admin_net':
    chain   => $chain,
    table   => 'filter',
    port    => $keystone_admin_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '023 nailgun_repo_admin':
    chain  => $chain,
    table  => 'filter',
    port   => $nailgun_repo_port,
    proto  => 'tcp',
    action => 'accept'
    state  => ['NEW'],
  }

  firewall { '024 allow loopback':
    chain   => 'INPUT',
    table   => 'filter',
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '025 allow icmp echo-request':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'echo-request',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '026 allow icmp echo-reply':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'echo-reply',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '027 allow icmp dest-unreach':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'destination-unreachable',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '028 allow icmp ttl-exceeded':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'ttl-exceeded',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '997 externally defined rules':
    chain  => $chain,
    table  => 'filter',
    jump   => 'ext-filter-input',
  }

  firewall { '998 accept related established rules':
    chain  => $chain,
    table  => 'filter',
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  firewall {'999 iptables denied':
    chain      => 'INPUT',
    table      => 'filter',
    limit      => '5/min',
    jump       => 'LOG',
    log_prefix => 'iptables denied: ',
    log_level  => '7',
  }

  ## FORWARD:filter:IPv4

  firewall { '001 forward admin_net':
    chain   => 'FORWARD',
    table   => 'filter',
    proto   => 'all',
    source  => "${network_address}/${network_cidr}",
    iniface => $admin_iface,
    state   => ['NEW'],
    action  => 'accept',
  }

  firewall { '002 forward admin_net conntrack':
    chain   => 'FORWARD',
    table   => 'filter',
    proto   => 'all',
    state   => ['RELATED', 'ESTABLISHED'],
    action  => 'accept'
  }

  firewall { '999 externally defined rules':
    chain  => 'FORWARD',
    table  => 'filter',
    jump   => 'ext-filter-forward',
  }

  ## POSTROUTING:nat:IPv4

  #Host services
  firewall { '001 forward_admin_net':
    chain    => 'POSTROUTING',
    table    => 'nat',
    proto    => 'all',
    source   => "${network_address}/${network_cidr}",
    outiface => 'e+',
    jump     => 'MASQUERADE',
  }

  firewall { '999 externally defined rules':
    chain  => 'POSTROUTING',
    table  => 'nat',
    jump   => 'ext-nat-postrouting',
  }

  ## POSTROUTING:mangle:IPv4

  firewall { '001 recalculate dhcp checksum':
    chain         => 'POSTROUTING',
    table         => 'mangle',
    proto         => 'udp',
    port          => 68,
    jump          => 'CHECKSUM',
    checksum_fill => true,
  }

  firewall { '999 externally defined rules':
    chain  => 'POSTROUTING',
    table  => 'mangle',
    jump   => 'ext-mangle-postrouting',
  }
}
