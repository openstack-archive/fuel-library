import 'globals.pp'

class { "l23network::hosts_file":
  nodes => $nodes_hash,
}
