class osnailyfacter::hosts::hosts {

  notice('MODULAR: hosts/hosts.pp')

  $hosts_file = '/etc/hosts'
  $network_metadata = hiera_hash('network_metadata')
  $host_resources = network_metadata_to_hosts($network_metadata)
  $deleted_nodes = hiera('deleted_nodes', [])
  $messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', hiera('node_name_prefix_for_messaging'))
  $host_hash = merge($host_resoruces, $messaging_host_resources,
    {ensure => present})

  Host {
      target => $hosts_file
  }

  create_resources(host, merge($host_resources, $messaging_host_resources))
  if !empty($deleted_nodes) {
    create_resources(host, $deleted_nodes, {ensure => absent})
  }
}
