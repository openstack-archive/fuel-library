class osnailyfacter::hosts::hosts {

  notice('MODULAR: hosts/hosts.pp')

  $hosts_file = '/etc/hosts'
  $network_metadata = hiera_hash('network_metadata')
  $messaging_prefix = hiera('node_name_prefix_for_messaging')
  $host_resources = network_metadata_to_hosts($network_metadata)
  $messaging_host_resources = network_metadata_to_hosts($network_metadata, 'mgmt/messaging', $messaging_prefix)

  $deleted_nodes = difference(hiera('deleted_nodes', []), keys($host_resources))
  $deleted_messaging_nodes = prefix($deleted_nodes, $messaging_prefix)

  Host {
      target => $hosts_file
  }

  # Bug LP1624143 : hosts should be consistently ordered
  create_resources(host, $host_resources, { tag => 'host_resources' } )
  create_resources(host, $messaging_host_resources, { tag => 'messaging_host_resources' } )

  Host<| tag == 'host_resources' |> -> Host<| tag == 'messaging_host_resources' |>

  if !empty($deleted_nodes) {
    ensure_resource(host, unique(concat($deleted_nodes, $deleted_messaging_nodes)), {ensure => absent})
  }

}
