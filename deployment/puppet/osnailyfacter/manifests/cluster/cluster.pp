class osnailyfacter::cluster::cluster {

  notice('MODULAR: cluster/cluster.pp')

  if (!roles_include(hiera('corosync_roles')) && !tags_include(hiera('corosync_tags'))) {
    fail('The node roles/tags is not in corosync roles/tags')

  prepare_network_config(hiera_hash('network_scheme', {}))

  $corosync_nodes_by_roles = corosync_nodes(
      get_nodes_hash_by_roles(
          hiera_hash('network_metadata'),
          hiera('corosync_roles')
      ),
      'mgmt/corosync'
  )

  $corosync_nodes_by_tags = corosync_nodes(
    get_nodes_hash_by_tags( hiera_hash('network_metadata'), hiera('corosync_tags') ),
      'mgmt/corosync'
  )

  $corosync_nodes = empty($corosync_nodes_by_tags) ? {
    true    => $corosync_nodes_by_roles,
    false   => $corosync_nodes_by_tags,
    default => $corosync_nodes_by_roles,
  }

  # Sort the corosync nodes by node IDs
  # and then extract IPs, IDs and host names as lists
  $corosync_nodes_processed = corosync_nodes_process($corosync_nodes)

  $cluster_recheck_interval = hiera('cluster_recheck_interval', '190s')

  class { '::cluster':
    internal_address         => get_network_role_property('mgmt/corosync', 'ipaddr'),
    quorum_members           => $corosync_nodes_processed['ips'],
    unicast_addresses        => $corosync_nodes_processed['ips'],
    quorum_members_ids       => $corosync_nodes_processed['ids'],
    cluster_recheck_interval => $cluster_recheck_interval,
  }

  pcmk_nodes { 'pacemaker' :
    nodes               => $corosync_nodes,
    add_pacemaker_nodes => false,
  }

  Service <| title == 'corosync' |> {
    subscribe => File['/etc/corosync/service.d'],
    require   => File['/etc/corosync/corosync.conf'],
  }

  Service['corosync'] -> Pcmk_nodes<||>
  Pcmk_nodes<||> -> Service<| provider == 'pacemaker' |>

  # Sometimes during first start pacemaker can not connect to corosync
  # via IPC due to pacemaker and corosync processes are run under different users
  if($::operatingsystem == 'Ubuntu') {
    $pacemaker_run_uid = 'hacluster'
    $pacemaker_run_gid = 'haclient'

    file {'/etc/corosync/uidgid.d/': ensure => directory }

    file {'/etc/corosync/uidgid.d/pacemaker':
      content => "uidgid {
   uid: ${pacemaker_run_uid}
   gid: ${pacemaker_run_gid}
}",
      require => File['/etc/corosync/uidgid.d/']
    }

    File['/etc/corosync/corosync.conf'] -> File['/etc/corosync/uidgid.d/pacemaker'] -> Service <| title == 'corosync' |>
  }

}
