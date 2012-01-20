define ringbuilder::rebalance() {
  validate_re($name, '^object|contianer|account$')
  exec { "rebalance_${name}":
    command     => "swift-ring-builder ${name}.builder rebalance",
    path        => ['/usr/bin'],
    refreshonly => true,
  }
}
