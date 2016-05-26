class osnailyfacter::cluster::cluster {

  notice('MODULAR: cluster/cluster.pp')

  if ! roles_include(hiera('corosync_roles')) {
    fail('The node role is not in corosync roles')
  }

  prepare_network_config(hiera_hash('network_scheme', {}))

  $cluster_recheck_interval = hiera('cluster_recheck_interval', '190s')

  $corosync_nodes = corosync_nodes(
    get_nodes_hash_by_roles(
      hiera_hash('network_metadata'),
      hiera('corosync_roles')
    ),
    'mgmt/corosync'
  )

  class { '::cluster' :
    cluster_nodes            => $corosync_nodes,
    cluster_recheck_interval => $cluster_recheck_interval,
  }

}
