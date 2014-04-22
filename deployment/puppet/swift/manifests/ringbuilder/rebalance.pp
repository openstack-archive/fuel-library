# Swift::Ring::Rebalance
#   Reblances the specified ring. Assumes that the ring already exists
#   and is stored at /etc/swift/${name}.builder
#
# == Parameters
#
# [*name*] Type of ring to rebalance. The ring file is assumed to be at the path
#   /etc/swift/${name}.builder
define swift::ringbuilder::rebalance() {

  validate_re($name, '^object|container|account$')

  if ! defined(Anchor['rebalance_begin']) {
    anchor {'rebalance_begin':}
  }

  if ! defined(Anchor['rebalance_end']) {
    anchor {'rebalance_end':}
  }

  Anchor['rebalance_begin'] -> Exec["hours_passed_${name}"] -> Exec["rebalance_${name}"] -> Anchor["rebalance_end"]

  exec { "hours_passed_${name}":
    command  => "swift-ring-builder /etc/swift/${name}.builder pretend_min_part_hours_passed",
    path     => ['/usr/bin','/bin'],
    user     => 'swift',
    returns  => [0,1],
  }

  exec { "rebalance_${name}":
    command     => "swift-ring-builder /etc/swift/${name}.builder rebalance",
    path        => ['/usr/bin','/bin'],
    timeout     => 900,
    user        => 'swift',
    returns     => [0,1],
  }


}
