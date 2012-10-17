class quantum::params {
  case $::osfamily {
    'Debian', 'Ubuntu': {
      $package_name       = 'quantum-common'
      $server_package     = 'quantum-server'
      $server_service     = 'quantum-server'

      $ovs_agent_package  = 'quantum-plugin-openvswitch-agent'
      $ovs_agent_service  = 'quantum-plugin-openvswitch-agent'
      $ovs_server_package = 'quantum-plugin-openvswitch'

      $dhcp_package       = 'quantum-dhcp-agent'
      $dhcp_service       = 'quantum-dhcp-agent'

      $l3_package         = 'quantum-l3-agent'
      $l3_service         = 'quantum-l3-agent'

      $cliff_package      = 'python-cliff'
      $kernel_headers     = "linux-headers-${::kernelrelease}"
    }
  }
}
