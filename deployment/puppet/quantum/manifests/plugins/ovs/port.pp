define quantum::plugins::ovs::port {
  $mapping = split($name, ":")
  $bridge  = $mapping[0]
  $port    = $mapping[1]

  if !defined(L23network::L2::Port[$port]) {
    l23network::l2::port {$port:
      ensure => present,
      bridge => $bridge,
      skip_existing => true,
    }
  }
}
