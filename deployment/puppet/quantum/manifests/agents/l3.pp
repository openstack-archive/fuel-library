class quantum::agents::l3 (
  $interface_driver         = "quantum.agent.linux.interface.OVSInterfaceDriver",
  $use_namespaces           = "False",
  $router_id                = "7e5c2aca-bbac-44dd-814d-f2ea9a4003e4",
  $gateway_external_net_id  = "3f8699d7-f221-421a-acf5-e41e88cfd54f",
  $metadata_ip              = "169.254.169.254",
  $external_network_bridge  = "br-ex",
  $root_helper              = "sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf"
) inherits quantum {
  Package["quantum-l3-agent"] -> Quantum_l3_agent_config<||>
  Quantum_config<||> ~> Service["quantum-l3"]
  Quantum_l3_agent_config<||> ~> Service["quantum-l3"]

  quantum_l3_agent_config {
    "DEFAULT/debug":                     value => $log_debug;
    "DEFAULT/auth_host":                value => $auth_host;
    "DEFAULT/auth_port":                value => $auth_port;
    "DEFAULT/auth_uri":                 value => $auth_uri;
    "DEFAULT/admin_tenant_name":        value => $keystone_tenant;
    "DEFAULT/admin_user":               value => $keystone_user;
    "DEFAULT/admin_password":           value => $keystone_password;
    "DEFAULT/use_namespaces":            value => $use_namespaces;
    "DEFAULT/router_id":                 value => $router_id;
    "DEFAULT/gateway_external_net_id":   value => $gateway_external_net_id;
    "DEFAULT/metadata_ip":               value => $metadata_ip;
    "DEFAULT/external_network_bridge":   value => $external_network_bridge;
    "DEFAULT/root_helper":              value => $root_helper;
  }

  package { 'quantum-l3':
    name    => $::quantum::params::l3_package,
    ensure  => $package_ensure,
    require => Class['quantum'],
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'quantum-l3':
    name    => $::quantum::params::l3_service,
    enable  => $enabled,
    ensure  => $ensure,
    require => [Package[$::quantum::params::l3_package], Class['quantum']],
  }
}
