class osnailyfacter::hosts::hosts {

  notice('MODULAR: hosts/hosts.pp')

  $hosts_file = '/etc/hosts'
  $network_metadata = hiera_hash('network_metadata')
  $messaging_prefix = hiera('node_name_prefix_for_messaging')
  $host_resources = network_metadata_to_hosts($network_metadata)
  $messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', $messaging_prefix)
  $host_hash = merge($host_resources, $messaging_host_resources)

  $deleted_nodes = hiera('deleted_nodes', [])
  $deleted_messaging_nodes = prefix($deleted_nodes, $messaging_prefix)
  $nodes_to_delete = unique(concat($deleted_nodes, $deleted_messaging_nodes))
  # convert array of host to hash for create_resources
  $nodes_to_delete_hash = reduce($nodes_to_delete, {}) |$cumulative, $host| {
    merge($cumulative, { "${host}" => {} })
  }

  Host {
      target => $hosts_file
  }

  create_resources(host, $host_hash)
  if !empty($deleted_nodes) {
    create_resources(host, $nodes_to_delete_hash, {ensure => absent})
  }
}
