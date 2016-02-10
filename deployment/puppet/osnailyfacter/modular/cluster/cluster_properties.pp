notice('MODULAR: cluster_properties.pp')

if ! roles_include(hiera('corosync_roles')) {
  fail('The node role is not in corosync roles')
}

$corosync_nodes_in_cluster = corosync_nodes_in_cluster()
$cluster_recheck_interval = hiera('cluster_recheck_interval', '190s')

if count($corosync_nodes_in_cluster) > 2 {
  $quorum_policy = 'stop'
} else {
  $quorum_policy = 'ignore'
}

Cs_property['no-quorum-policy']->
  Cs_property['stonith-enabled']->
    Cs_property['start-failure-is-fatal']

Cs_property {
  ensure   => present,
  provider => 'crm',
}

cs_property { 'no-quorum-policy':
  value => $quorum_policy,
}

cs_property { 'stonith-enabled':
  value => false,
}

cs_property { 'start-failure-is-fatal':
  value => false,
} 

cs_property { 'symmetric-cluster':
  value => false,
}

cs_property { 'cluster-recheck-interval':
  value => $cluster_recheck_interval,
}
