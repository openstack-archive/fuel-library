class quantum::agents::dhcp (
  $package_ensure   = 'present',
  $enabled          = true,
  $debug            = 'False',
  $state_path       = '/var/lib/quantum',
  $resync_interval  = 30,
  $interface_driver = 'quantum.agent.linux.interface.OVSInterfaceDriver',
  $dhcp_driver      = 'quantum.agent.linux.dhcp.Dnsmasq',
  $use_namespaces   = 'True',
  $root_helper      = 'sudo /usr/bin/quantum-rootwrap /etc/quantum/rootwrap.conf'
) {

  include 'quantum::params'

  if $::quantum::params::dhcp_agent_package {
    Package['quantum'] -> Package['quantum-dhcp-agent']

    $dhcp_agent_package = 'quantum-dhcp-agent'

    package { 'quantum-dhcp-agent':
      name    => $::quantum::params::dhcp_agent_package,
      ensure  => $package_ensure,
    }
  } else {
    $dhcp_agent_package = $::quantum::params::package_name
  }

  case $dhcp_driver {
    /\.Dnsmasq/: {
      package { $::quantum::params::dnsmasq_packages:
        ensure => present,
        before => Package[$dhcp_agent_package],
      }
      $dhcp_server_packages = $::quantum::params::dnsmasq_packages
    }
    default: {
      fail("${dhcp_driver} is not supported as of now")
    }
  }

  Package[$dhcp_agent_package] -> Quantum_dhcp_agent_config<||>
  Package[$dhcp_agent_package] -> Quantum_config<||>

  Quantum_config<||> ~> Service['quantum-dhcp-service']
  Quantum_dhcp_agent_config<||> ~> Service['quantum-dhcp-service']

  quantum_dhcp_agent_config {
    'DEFAULT/debug':              value => $debug;
    'DEFAULT/state_path':         value => $state_path;
    'DEFAULT/resync_interval':    value => $resync_interval;
    'DEFAULT/interface_driver':   value => $interface_driver;
    'DEFAULT/dhcp_driver':        value => $dhcp_driver;
    'DEFAULT/use_namespaces':     value => $use_namespaces;
    'DEFAULT/root_helper':        value => $root_helper;
  }

  if $enabled {
    $ensure = 'running'
  } else {
    $ensure = 'stopped'
  }

  service { 'quantum-dhcp-service':
    name       => $::quantum::params::dhcp_agent_service,
    enable     => $enabled,
    ensure     => $ensure,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::quantum::params::service_provider,
    require    => [Package[$dhcp_agent_package], Class['quantum'], Service['quantum-plugin-ovs-service']],
  }

}
