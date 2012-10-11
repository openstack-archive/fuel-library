# Swift::Ring::Rebalance
#   Reblances the specified ring. Assumes that the ring already exists
#   and is stored at /etc/swift/${name}.builder
#
# == Parameters
#
# [*name*] Type of ring to rebalance. The ring file is assumed to be at the path
#   /etc/swift/${name}.builder
define swift::ringbuilder_multi::rebalance($ring_type) {

  validate_re($ring_type, '^object|container|account$')

  exec { "rebalance_${name}":
    command     => "swift-ring-builder /etc/swift/${ring_type}.builder rebalance",
    path        => ['/usr/bin'],
    refreshonly => true,
  }
}
