import 'globals.pp'

if ($deployment_mode == 'ha') or ($deployment_mode == 'ha_compact') {

  $multicast_address = '239.1.1.2'
  $secauth = 'off'
  $stonith = 'false'
  $quorum_policy = 'ignore'
  $expected_quorum_votes = "2"

  anchor {'corosync':}

  Anchor['corosync'] -> Cs_property<||>

  Class['::corosync']->Cs_shadow<||>
  Class['::corosync']->Cs_property<||>->Cs_resource<||>
  Cs_property<||>->Cs_shadow<||>
  Cs_property['no-quorum-policy']->Cs_property['stonith-enabled']->Cs_property['start-failure-is-fatal']

  file {'filter_quantum_ports.py':
    path   =>'/usr/bin/filter_quantum_ports.py',
    mode   => '0744',
    owner  => root,
    group  => root,
    source => "puppet:///modules/openstack/filter_quantum_ports.py",
  }

  Anchor['corosync'] ->
  corosync::service { 'pacemaker':
    version => '0',
  }
  Corosync::Service['pacemaker'] ~> Service['corosync']
  Corosync::Service['pacemaker'] -> Anchor['corosync-done']

  class { '::corosync':
    enable_secauth    => $secauth,
    bind_address      => $internal_address,
    multicast_address => $multicast_address,
    unicast_addresses => $controller_internal_addresses
  } -> Anchor['corosync-done']

  cs_property { 'no-quorum-policy':
    ensure => present,
    value  => $quorum_policy,
    retries => 5
  } -> Anchor['corosync-done']

  cs_property { 'stonith-enabled':
    ensure => present,
    value  => $stonith,
  } -> Anchor['corosync-done']

  cs_property { 'start-failure-is-fatal':
    ensure => present,
    value  => "false",
  } -> Anchor['corosync-done']

  cs_property { 'symmetric-cluster':
    ensure => present,
    value  => "false",
  } -> Anchor['corosync-done']

  anchor {'corosync-done':}

  file { 'ocf-mirantis-path':
    ensure  => directory,
    path    =>'/usr/lib/ocf/resource.d/mirantis',
    recurse => true,
    owner   => root,
    group   => root,
  }
  Package['corosync'] -> File['ocf-mirantis-path']
  Package<| title == 'pacemaker' |> -> File<| title == 'ocf-mirantis-path' |>

}
