#
define neutron::plugins::ovs::port {
  $mapping = split($name, ':')
  vs_port {$mapping[1]:
    ensure => present,
    bridge => $mapping[0]
  }
}

