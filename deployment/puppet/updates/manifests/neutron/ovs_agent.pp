class updates::neutron::ovs_agent(
  $pacemaker = false,
) inherits neutron::params {


  if $ovs_agent_package {
    $ovs_package = $ovs_agent_package
  } else {
    $ovs_package = $ovs_server_package
  }

  package {  $ovs_package :
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

  Package[$ovs_package] ~> Service[$ovs_agent_service]
 
}