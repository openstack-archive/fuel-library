class fuel::iptables (
  $network_address,
  $network_cidr,

  $admin_iface                = $::fuel::params::admin_interface,
  $ssh_port                   = '22',
  $ssh_network                = '0.0.0.0/0',
  $ssh_rseconds               = 60,
  $ssh_rhitcount              = 4,
  $nailgun_web_port           = $::fuel::params::nailgun_port,
  $nailgun_internal_port      = $::fuel::params::nailgun_internal_port,
  $nailgun_serialization_port = $::fuel::params::nailgun_serialization_port,
  $nailgun_repo_port          = $::fuel::params::repo_port,
  $postgres_port              = $::fuel::params::db_port,
  $ostf_port                  = $::fuel::params::ostf_port,
  $rsync_port                 = '873',
  $rsyslog_port               = '514',
  $ntp_port                   = '123',
  $rabbitmq_ports             = ['4369','5672','61613'],
  $rabbitmq_admin_port        = '15672',
  $fuelweb_port               = $::fuel::params::nailgun_ssl_port,
  $keystone_port              = $::fuel::params::keystone_port,
  $keystone_admin_port        = $::fuel::params::keystone_admin_port,
  $chain                      = 'INPUT',
  ) inherits fuel::params {

  #Enable cobbler's iptables rules even if Cobbler not called
  include ::cobbler::iptables

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

  firewall { '000 allow loopback':
    chain   => 'INPUT',
    table   => 'filter',
    proto   => 'all',
    iniface => 'lo',
    action  => 'accept',
  }

  # use SSH brute frorce protection only for external networks
  if $ssh_network == '0.0.0.0/0' {

    firewall { '007 ssh: new pipe for a sessions':
      proto   => 'tcp',
      dport   => $ssh_port,
      iniface => "! $admin_iface",
      state   => 'NEW',
      recent  => 'set',
    }

    firewall { '008 ssh: more than allowed attempts logged':
      proto      => 'tcp',
      dport      => $ssh_port,
      iniface    => "! $admin_iface",
      state      => 'NEW',
      recent     => 'update',
      rseconds   => $ssh_rseconds,
      rhitcount  => $ssh_rhitcount,
      jump       => 'LOG',
      log_prefix => 'iptables SSH brute-force: ',
      log_level  => '7',
    }

    firewall { '009 ssh: block more than allowed attempts':
      proto     => 'tcp',
      dport     => $ssh_port,
      iniface   => "! $admin_iface",
      state     => 'NEW',
      recent    => 'update',
      rseconds  => $ssh_rseconds,
      rhitcount => $ssh_rhitcount,
      action    => 'drop',
    }

  }

  firewall { '010 ssh':
    chain  => $chain,
    table  => 'filter',
    dport  => $ssh_port,
    proto  => 'tcp',
    source => $ssh_network,
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '020 ntp':
    chain   => $chain,
    table   => 'filter',
    dport   => $ntp_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '030 ntp_udp':
    chain   => $chain,
    table   => 'filter',
    dport   => $ntp_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '040 snmp':
    chain  => $chain,
    table  => 'filter',
    dport  => '162',
    proto  => 'udp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '050 nailgun_web':
    chain  => $chain,
    table  => 'filter',
    dport  => $nailgun_web_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '060 nailgun_internal':
    chain   => $chain,
    table   => 'filter',
    dport   => $nailgun_internal_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '065 nailgun_serialization_port':
    chain   => $chain,
    table   => 'filter',
    dport   => $nailgun_serialization_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '070 nailgun_internal_block_ext':
    chain  => $chain,
    table  => 'filter',
    dport  => $nailgun_internal_port,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '080 postgres_local':
    chain    => $chain,
    table    => 'filter',
    dport    => $postgres_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
    state    => ['NEW'],
  }

  firewall { '090 postgres':
    chain   => $chain,
    table   => 'filter',
    dport   => $postgres_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '100 postgres_block_ext':
    chain  => $chain,
    table  => 'filter',
    dport  => $postgres_port,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '110 ostf_admin':
    chain   => $chain,
    table   => 'filter',
    dport   => $ostf_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '120 ostf_local':
    chain    => $chain,
    table    => 'filter',
    dport    => $ostf_port,
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
    state    => ['NEW'],
  }

  firewall { '130 ostf_block_ext':
    chain  => $chain,
    table  => 'filter',
    dport  => $ostf_port,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '140 rsync':
    chain  => $chain,
    table  => 'filter',
    dport  => $rsync_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '150 rsyslog':
    chain   => $chain,
    table   => 'filter',
    dport   => $rsyslog_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '160 rsyslog':
    chain   => $chain,
    table   => 'filter',
    dport   => $rsyslog_port,
    proto   => 'udp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '170 rabbitmq_admin_net':
    chain   => $chain,
    table   => 'filter',
    dport   => $rabbitmq_ports,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '180 rabbitmq_local':
    chain    => $chain,
    table    => 'filter',
    dport    => concat($rabbitmq_ports, $rabbitmq_admin_port),
    proto    => 'tcp',
    src_type => 'LOCAL',
    action   => 'accept',
    state    => ['NEW'],
  }

  firewall { '190 rabbitmq_block_ext':
    chain  => $chain,
    table  => 'filter',
    dport  => $rabbitmq_ports,
    proto  => 'tcp',
    action => 'reject',
    state  => ['NEW'],
  }

  firewall { '200 fuelweb_port':
    chain  => $chain,
    table  => 'filter',
    dport  => $fuelweb_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '210 keystone_admin':
    chain  => $chain,
    table  => 'filter',
    dport  => $keystone_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '220 keystone_admin_port admin_net':
    chain   => $chain,
    table   => 'filter',
    dport   => $keystone_admin_port,
    proto   => 'tcp',
    iniface => $admin_iface,
    action  => 'accept',
    state   => ['NEW'],
  }

  firewall { '230 nailgun_repo_admin':
    chain  => $chain,
    table  => 'filter',
    dport  => $nailgun_repo_port,
    proto  => 'tcp',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '240 allow icmp echo-request':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'echo-request',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '250 allow icmp echo-reply':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'echo-reply',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '260 allow icmp dest-unreach':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'destination-unreachable',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '270 allow icmp time-exceeded':
    chain  => 'INPUT',
    table  => 'filter',
    proto  => 'icmp',
    icmp   => 'time-exceeded',
    action => 'accept',
    state  => ['NEW'],
  }

  firewall { '970 externally defined rules: ext-filter-input':
    chain => 'INPUT',
    table => 'filter',
    proto => 'all',
    jump  => 'ext-filter-input',
  }

  firewall { '980 accept related established rules':
    chain  => $chain,
    table  => 'filter',
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  firewall { '999 iptables denied':
    chain      => 'INPUT',
    table      => 'filter',
    proto      => 'all',
    limit      => '5/min',
    jump       => 'LOG',
    log_prefix => 'iptables denied: ',
    log_level  => '7',
  }

  ## FORWARD:filter:IPv4

  firewall { '010 forward admin_net':
    chain   => 'FORWARD',
    table   => 'filter',
    proto   => 'all',
    source  => "${network_address}/${network_cidr}",
    iniface => $admin_iface,
    state   => ['NEW'],
    action  => 'accept',
  }

  firewall { '970 externally defined rules':
    chain => 'FORWARD',
    table => 'filter',
    proto => 'all',
    jump  => 'ext-filter-forward',
  }

  firewall { '980 forward admin_net conntrack':
    chain  => 'FORWARD',
    table  => 'filter',
    proto  => 'all',
    state  => ['RELATED', 'ESTABLISHED'],
    action => 'accept',
  }

  ## POSTROUTING:nat:IPv4

  firewall { '010 forward_admin_net':
    chain    => 'POSTROUTING',
    table    => 'nat',
    proto    => 'all',
    source   => "${network_address}/${network_cidr}",
    outiface => 'e+',
    jump     => 'MASQUERADE',
  }

  firewall { '980 externally defined rules: ext-nat-postrouting':
    chain => 'POSTROUTING',
    table => 'nat',
    proto => 'all',
    jump  => 'ext-nat-postrouting',
  }

  ## POSTROUTING:mangle:IPv4

  firewall { '010 recalculate dhcp checksum':
    chain         => 'POSTROUTING',
    table         => 'mangle',
    proto         => 'udp',
    dport         => 68,
    jump          => 'CHECKSUM',
    checksum_fill => true,
  }

  firewall { '980 externally defined rules: ext-mangle-postrouting':
    chain => 'POSTROUTING',
    table => 'mangle',
    proto => 'all',
    jump  => 'ext-mangle-postrouting',
  }
}
