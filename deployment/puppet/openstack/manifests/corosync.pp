class openstack::corosync (
  $bind_address             = '127.0.0.1',
  $multicast_address        = undef,
  $secauth                  = false,
  $stonith                  = false,
  $quorum_policy            = 'ignore',
  $quorum_members           = ['localhost'],
  $quorum_members_ids       = undef,
  $unicast_addresses        = ['127.0.0.1'],
  $packages                 = undef,
  $cluster_recheck_interval = '190s',
) {

  anchor {'corosync':}

  if $packages {
    package { $packages:
      ensure => present,
    } -> Anchor['corosync-done']
  }
  Anchor['corosync'] ->
    Pcmk_property<||>


  Class['::corosync']->
    Pcmk_property<||>->
      Pcmk_resource<||>

  Pcmk_property['no-quorum-policy']->
    Pcmk_property['stonith-enabled']->
      Pcmk_property['start-failure-is-fatal']

  corosync::service { 'pacemaker':
    version => '1',
  }

  Anchor['corosync'] -> Corosync::Service['pacemaker']
  Corosync::Service['pacemaker'] ~> Service['corosync']
  Corosync::Service['pacemaker'] -> Anchor['corosync-done']


  class { '::corosync':
    enable_secauth           => $secauth,
    bind_address             => $bind_address,
    multicast_address        => $multicast_address,
    set_votequorum           => true,
    manage_pacemaker_service => true,
    quorum_members           => $quorum_members,
    quorum_members_ids       => $quorum_members_ids,
    unicast_addresses        => $unicast_addresses,
    # NOTE(bogdando) debug is *too* verbose
    debug                    => false,
    log_stderr               => false,
    log_function_name        => true,
    # NOTE(scsnow) workaround for rhel7.2
    cluster_name             => 'openstack',
  } ->
  Anchor['corosync-done']

  Pcmk_property {
    ensure   => 'present',
  }

  pcmk_property { 'no-quorum-policy':
    value   => $quorum_policy,
  } -> Anchor['corosync-done']

  pcmk_property { 'stonith-enabled':
    value  => $stonith,
  } -> Anchor['corosync-done']

  pcmk_property { 'start-failure-is-fatal':
    value  => false,
  } -> Anchor['corosync-done']

  pcmk_property { 'symmetric-cluster':
    value  => false,
  } -> Anchor['corosync-done']

  pcmk_property { 'cluster-recheck-interval':
    value    => $cluster_recheck_interval,
  } -> Anchor['corosync-done']

  anchor {'corosync-done':}
}
