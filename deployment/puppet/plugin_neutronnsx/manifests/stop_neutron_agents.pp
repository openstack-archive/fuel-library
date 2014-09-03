class plugin_neutronnsx::stop_neutron_agents {

  Service <| title == 'neutron-ovs-agent-service' |> {
    ensure => stopped,
  }

  Service <| title == 'neutron-l3' |> {
    ensure => stopped,
  }

}
