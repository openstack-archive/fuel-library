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

  Host {
      target => $hosts_file
  }

  create_resources(host, $host_hash)
  if !empty($deleted_nodes) {
    ensure_resource(host, unique(concat($deleted_nodes, $deleted_messaging_nodes)), {ensure => absent})
  }
}
