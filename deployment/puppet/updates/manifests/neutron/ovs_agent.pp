class updates::neutron::ovs_agent(
  $pacemaker = false,
) inherits neutron::params {

  package {  $ovs_agent_package :
    ensure => 'latest',
  }

  service { $ovs_agent_service :
    ensure => 'running',
    enable => true,
  }

  if $pacemaker {
    Service[$ovs_agent_service] {
      provider => 'pacemaker',
    }
  }

  Package[$ovs_agent_package] ~> Service[$ovs_agent_service]
}
