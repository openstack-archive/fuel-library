# Swift::Ring::Rebalance
#   Reblances the specified ring. Assumes that the ring already exists
#   and is stored at /etc/swift/${name}.builder
#
# == Parameters
#
# [*name*] Type of ring to rebalance. The ring file is assumed to be at the path
#   /etc/swift/${name}.builder
#
# [*seed*] Optional. Seed value used to seed pythons pseudo-random for ringbuilding.
define swift::ringbuilder::rebalance(
  $seed = undef
) {

  validate_re($name, '^object|container|account$')
  if $seed {
    validate_re($seed, '^\d+$')
  }

  exec { "hours_passed_${name}":
    command     => "swift-ring-builder /etc/swift/${name}.builder pretend_min_part_hours_passed",
    path        => ['/usr/bin'],
    refreshonly => true,
    returns     => [0,1],
  } ->
  exec { "rebalance_${name}":
    command     => strip("swift-ring-builder /etc/swift/${name}.builder rebalance ${seed}"),
    path        => ['/usr/bin'],
    refreshonly => true,
    returns     => [0,1],
  }
}
