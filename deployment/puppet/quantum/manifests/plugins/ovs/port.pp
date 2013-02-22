define quantum::plugins::ovs::port {
  $mapping = split($name, ":")
  $bridge  = $mapping[0]
  $port    = $mapping[1]

  if !defined(l23network::l2::port[$port]) {
    l23network::l2::port {$port:
      ensure => present,
      bridge => $bridge,
      skip_existing => true,
    }
  }
}
