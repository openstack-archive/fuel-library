class quantum::agents::dhcp (
  $state_path         = "/var/lib/quantum",
  $interface_driver   = "quantum.agent.linux.interface.OVSInterfaceDriver",
  $dhcp_driver        = "quantum.agent.linux.dhcp.Dnsmasq",
  $use_namespaces     = "False",
  $root_helper        = "sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf"
) inherits quantum {
  Package["quantum-dhcp-agent"] -> Quantum_dhcp_agent_config<||>
  Quantum_config<||> ~> Service["quantum-dhcp-service"]
  Quantum_dhcp_agent_config<||> ~> Service["quantum-dhcp-service"]

  quantum_dhcp_agent_config {
    "DEFAULT/debug":              value => $log_debug;
    "DEFAULT/state_path":         value => $state_path;
    "DEFAULT/interface_driver":   value => $interface_driver;
    "DEFAULT/dhcp_driver":        value => $dhcp_driver;
    "DEFAULT/use_namespaces":     value => $use_namespaces;
    "DEFAULT/root_helper":        value => $root_helper;
  }

  package { 'quantum-dhcp-agent':
    name    => $::quantum::params::dhcp_package,
    ensure  => $package_ensure,
    require => Class['quantum'],
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'quantum-dhcp-service':
    name    => $::quantum::params::dhcp_service,
    enable  => $enabled,
    ensure  => $ensure,
    require => [Package[$::quantum::params::dhcp_package], Class['quantum']],
  }
}
