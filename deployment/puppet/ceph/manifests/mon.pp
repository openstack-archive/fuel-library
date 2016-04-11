# setup Ceph monitors
class ceph::mon (
  $mon_hosts        = $::ceph::mon_hosts,
  $mon_ip_addresses = $::ceph::mon_ip_addresses,
  $mon_addr         = $::ceph::mon_addr,
  $node_hostname    = $::ceph::node_hostname,
) {

  firewall {'010 ceph-mon allow':
    chain  => 'INPUT',
    dport  => 6789,
    proto  => 'tcp',
    action => accept,
  }

  exec {'ceph-deploy mon create':
    command   => "ceph-deploy mon create ${node_hostname}:${mon_addr}",
    logoutput => true,
    unless    => "ceph mon dump | grep -qE '^[0-9]+: +${mon_addr}:.* mon\\.${node_hostname}\$'",
  }

  exec {'Wait for Ceph quorum':
    command     => "ceph mon stat | grep -q 'quorum.*${node_hostname}'",
    tries       => 12,  # This is necessary to prevent a race: mon must establish
    # a quorum before it can generate keys, observed this takes upto 15 seconds
    # Keys must exist prior to other commands running
    try_sleep   => 5,
    refreshonly => true,
  }

  exec {'ceph-deploy gatherkeys':
    command   => "ceph-deploy gatherkeys ${node_hostname}",
    unless    => join(['test -f /root/ceph.bootstrap-mds.keyring',
                   '-f /root/ceph.bootstrap-osd.keyring',
                   '-f /root/ceph.client.admin.keyring',
                 ], ' -a '),
    try_sleep => 5,
    tries     => 6,
  }

  Firewall['010 ceph-mon allow'] ->
  Exec['ceph-deploy mon create'] ~>
  Exec['Wait for Ceph quorum']   ->
  Exec['ceph-deploy gatherkeys']

  if $node_hostname == $::ceph::primary_mon {

    # After the primary monitor has established a quorum, it is safe to
    # add other monitors to ceph.conf. All other Ceph nodes will get
    # these settings via 'ceph-deploy config pull' in ceph::conf.
    ceph_conf {
      'global/mon_host':            value => join($mon_ip_addresses, ' ');
      'global/mon_initial_members': value => join($mon_hosts, ' ');
    }

    Ceph_conf[['global/mon_host', 'global/mon_initial_members']] ->
    Exec['Wait for Ceph quorum']
  }
}
