class openstack::corosync (
  $bind_address          = '127.0.0.1',
  $multicast_address     = '239.1.1.2',
  $secauth               = false,
  $stonith               = false,
  $quorum_policy         = 'ignore',
  $expected_quorum_votes = '2',
  $unicast_addresses     = undef
) {

  file { 'limitsconf':
    ensure  => present,
    path    => '/etc/security/limits.conf',
    source  => 'puppet:///modules/openstack/limits.conf',
    replace => true,
    owner   => '0',
    group   => '0',
    mode    => '0644',
    before  => Service['corosync'],
  }

  anchor {'corosync':}

  Anchor['corosync'] -> Cs_property<||>

  Class['::corosync']->Cs_shadow<||>
  Class['::corosync']->Cs_property<||>->Cs_resource<||>
  Cs_property<||>->Cs_shadow<||>

  Cs_property['no-quorum-policy']->
    Cs_property['stonith-enabled']->
      Cs_property['start-failure-is-fatal']

  file {'filter_quantum_ports.py':
    path   =>'/usr/bin/filter_quantum_ports.py',
    mode   => '0744',
    owner  => root,
    group  => root,
    source => 'puppet:///modules/openstack/filter_quantum_ports.py',
  }

  Anchor['corosync'] ->
  corosync::service { 'pacemaker':
    version => '0',
  }
  Corosync::Service['pacemaker'] ~> Service['corosync']
  Corosync::Service['pacemaker'] -> Anchor['corosync-done']


  class { '::corosync':
    enable_secauth    => $secauth,
    bind_address      => $bind_address,
    multicast_address => $multicast_address,
    unicast_addresses => $unicast_addresses
  }

  #cs_property { 'expected-quorum-votes':
  #  ensure => present,
  #  value  => $expected_quorum_votes
  #}

  cs_property { 'no-quorum-policy':
    ensure  => present,
    value   => $quorum_policy,
    retries => 5
  } -> Anchor['corosync-done']

  cs_property { 'stonith-enabled':
    ensure => present,
    value  => $stonith,
  } -> Anchor['corosync-done']

  cs_property { 'start-failure-is-fatal':
    ensure => present,
    value  => false,
  } -> Anchor['corosync-done']

  cs_property { 'symmetric-cluster':
    ensure => present,
    value  => false,
  } -> Anchor['corosync-done']

  #cs_property { 'placement-strategy':
  #  ensure => absent,
  #  value  => 'default',
  #}

  anchor {'corosync-done':}
}
