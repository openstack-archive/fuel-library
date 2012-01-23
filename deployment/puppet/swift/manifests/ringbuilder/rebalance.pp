define swift::ringbuilder::rebalance() {

  validate_re($name, '^object|container|account$')

  exec { "rebalance_${name}":
    command     => "swift-ring-builder /etc/swift/${name}.builder rebalance",
    path        => ['/usr/bin'],
    refreshonly => true,
  }
}
