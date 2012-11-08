# Used to configure nodes that are responsible for managing swift rings.
# Rings are used to make decicions about how to map objects in the cluster
#
# Specifies the following relationship:
#  Rings should be created before any devices are added to them
#  Rings should be rebalanced if anything changes
# == Parameters
#  [*part_power*] The total number of partitions that should exist in the ring.
#    This is expressed as a power of 2.
#  [*replicas*] Numer of replicas that should be maintained of each stored object.
#  [*min_part_hours*] Minimum amount of time before partitions can be moved.
#
# == Dependencies
#
#   Class['swift']
#
# == Examples
#
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2011 Puppetlabs Inc, unless otherwise noted.
#
class swift::ringbuilder(
  $part_power = undef,
  $replicas = undef,
  $min_part_hours = undef
) {

  Class['swift'] -> Class['swift::ringbuilder']

  swift::ringbuilder::create{ ['object', 'account', 'container']:
    part_power     => $part_power,
    replicas       => $replicas,
    min_part_hours => $min_part_hours,
  }

  Swift::Ringbuilder::Create['object'] -> Ring_object_device <| |> ~> Swift::Ringbuilder::Rebalance['object']

  Swift::Ringbuilder::Create['container'] -> Ring_container_device <| |> ~> Swift::Ringbuilder::Rebalance['container']

  Swift::Ringbuilder::Create['account'] -> Ring_account_device <| |> ~> Swift::Ringbuilder::Rebalance['account']

  swift::ringbuilder::rebalance{ ['object', 'account', 'container']: }

}
