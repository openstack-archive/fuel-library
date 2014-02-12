# setup Ceph monitors
class ceph::mon (
  $mon_hosts        = $::ceph::mon_hosts,
  $mon_ip_addresses = $::ceph::mon_ip_addresses,
) {

  firewall {'010 ceph-mon allow':
    chain  => 'INPUT',
    dport  => 6789,
    proto  => 'tcp',
    action => accept,
  }

  exec {'ceph-deploy mon create':
    command   => "ceph-deploy mon create ${::hostname}:${::internal_address}",
    logoutput => true,
    unless    => "ceph mon stat | grep ${::internal_address}",
  }

  exec {'Wait for Ceph quorum':
    # this can be replaced with "ceph mon status mon.$::host" for Dumpling
    command   => 'ps ax|grep -vq ceph-create-keys',
    returns   => 0,
    tries     => 60,  # This is necessary to prevent a race: mon must establish
    # a quorum before it can generate keys, observed this takes upto 15 seconds
    # Keys must exist prior to other commands running
    try_sleep => 1,
  }

  exec {'ceph-deploy gatherkeys':
    command => "ceph-deploy gatherkeys ${::hostname}",
    creates => ['/root/ceph.bootstrap-mds.keyring',
                '/root/ceph.bootstrap-osd.keyring',
                '/root/ceph.client.admin.keyring',
               ],
  }

  Firewall['010 ceph-mon allow'] ->
  Exec['ceph-deploy mon create'] ->
  Exec['Wait for Ceph quorum']   ->
  Exec['ceph-deploy gatherkeys']

  if $::hostname == $::ceph::primary_mon {

    # After the primary monitor has established a quorum, it is safe to
    # add other monitors to ceph.conf. All other Ceph nodes will get
    # these settings via 'ceph-deploy config pull' in ceph::conf.
    ceph_conf {
      'global/mon_host':            value => join($mon_ip_addresses, ' ');
      'global/mon_initial_members': value => join($mon_hosts, ' ');
    }

    # Has to be an exec: Puppet can't reload a service without declaring
    # an ordering relationship.
    exec {'reload Ceph for HA':
      command   => 'service ceph reload',
      subscribe => [Ceph_conf['global/mon_host'], Ceph_conf['global/mon_initial_members']]
    }

    Exec['ceph-deploy gatherkeys'] ->
    Ceph_conf[['global/mon_host', 'global/mon_initial_members']] ->
    Exec['reload Ceph for HA']
  }
}
