class { "l23network::hosts_file":
  nodes => hiera('nodes'),
}
