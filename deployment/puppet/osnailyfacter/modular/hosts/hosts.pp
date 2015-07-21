notice('MODULAR: hosts.pp')

$network_metadata = hiera_hash('network_metadata')

osnailyfacter::hosts_file { 'all_nodes':
  nodes_hash   => $network_metadata['nodes'],
  network_role => 'mgmt/vip'
}

osnailyfacter::hosts_file { 'computes_for_live_migration':
  nodes_hash   => get_nodes_hash_by_roles($network_metadata, ['compute']),
  network_role => 'nova/migration',
  name_prefix  => hiera('compute_name_prefix_for_live_migration'),
  aliases      => false,
}
