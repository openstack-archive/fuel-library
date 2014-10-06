$nodes_hash = hiera('nodes')

class { 'l23network::hosts_file' :
  nodes => $nodes_hash,
}
