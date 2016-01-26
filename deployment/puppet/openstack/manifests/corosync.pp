class openstack::corosync (
  $bind_address             = '127.0.0.1',
  $multicast_address        = undef,
  $secauth                  = false,
  $stonith                  = false,
  $quorum_policy            = 'ignore',
  $quorum_members           = ['localhost'],
  $unicast_addresses        = ['127.0.0.1'],
  $packages                 = undef,
  $cluster_recheck_interval = '190s',
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

  if $packages {
    package { $packages:
      ensure => present,
    } -> Anchor['corosync-done']
  }

  Anchor['corosync'] -> Cs_property<||>

  Class['::corosync']->Cs_shadow<||>
  Class['::corosync']->Cs_property<||>->Cs_resource<||>
  Cs_property<||>->Cs_shadow<||>

  Cs_property['no-quorum-policy']->
    Cs_property['stonith-enabled']->
      Cs_property['start-failure-is-fatal']

  corosync::service { 'pacemaker':
    version => '1',
  }

  Anchor['corosync'] -> Corosync::Service['pacemaker']
  Corosync::Service['pacemaker'] ~> Service['corosync']
  Corosync::Service['pacemaker'] -> Anchor['corosync-done']


  class { '::corosync':
    enable_secauth    => $secauth,
    bind_address      => $bind_address,
    multicast_address => $multicast_address,
    set_votequorum    => true,
    quorum_members    => $quorum_members,
    unicast_addresses => $unicast_addresses,
    # NOTE(bogdando) debug is *too* verbose
    debug              => false,
  } ->
  service { 'pacemaker':
    ensure    => running,
    enable    => true,
    subscribe => Service['corosync'],
  } ->
  Anchor['corosync-done']

  Cs_property {
    ensure   => present,
    provider => 'crm',
  }

  cs_property { 'no-quorum-policy':
    value   => $quorum_policy,
  } -> Anchor['corosync-done']

  cs_property { 'stonith-enabled':
    value  => $stonith,
  } -> Anchor['corosync-done']

  cs_property { 'start-failure-is-fatal':
    value  => false,
  } -> Anchor['corosync-done']

  cs_property { 'symmetric-cluster':
    value  => false,
  } -> Anchor['corosync-done']

  cs_property { 'cluster-recheck-interval':
    value    => $cluster_recheck_interval,
  } -> Anchor['corosync-done']

  anchor {'corosync-done':}
}
