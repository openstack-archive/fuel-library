class osnailyfacter::cluster::cluster {

  notice('MODULAR: cluster/cluster.pp')

  if ! roles_include(hiera('corosync_roles')) {
    fail('The node role is not in corosync roles')
  }

  prepare_network_config(hiera_hash('network_scheme', {}))

  $cluster_recheck_interval = hiera('cluster_recheck_interval', '190s')

  class { '::cluster':
  }

}
