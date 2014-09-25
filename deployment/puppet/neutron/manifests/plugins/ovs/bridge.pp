#
define neutron::plugins::ovs::bridge {
  $mapping = split($name, ':')
  $bridge = $mapping[1]

  vs_bridge {$bridge:
    ensure       => present,
    external_ids => "bridge-id=${bridge}"
  }
}

