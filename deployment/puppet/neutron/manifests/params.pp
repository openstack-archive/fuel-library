class neutron::params {
  case $::osfamily {
    'Debian', 'Ubuntu': {
      $package_name       = 'neutron-common'
      $server_package     = 'neutron-server'
      $server_service     = 'neutron-server'

      $ovs_agent_package  = 'neutron-plugin-openvswitch-agent'
      $ovs_agent_service  = 'neutron-plugin-openvswitch-agent'
      $ovs_server_package = 'neutron-plugin-openvswitch'
      $ovs_cleanup_service = false

      $dhcp_agent_package = 'neutron-dhcp-agent'
      $dhcp_agent_service = 'neutron-dhcp-agent'

      $dnsmasq_packages   = ['dnsmasq-base', 'dnsmasq-utils']

      $isc_dhcp_packages  = ['isc-dhcp-server']

      $l3_agent_package   = 'neutron-l3-agent'
      $l3_agent_service   = 'neutron-l3-agent'

      $linuxbridge_agent_package  = 'neutron-plugin-linuxbridge-agent'
      $linuxbridge_agent_service  = 'neutron-plugin-linuxbridge-agent'
      $linuxbridge_server_package = 'neutron-plugin-linuxbridge'
      $linuxbridge_config_file    = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'

      $metadata_agent_package = 'neutron-metadata-agent'
      $metadata_agent_service = 'neutron-metadata-agent'

      $cliff_package      = 'python-cliff'
      $kernel_headers     = "linux-headers-${::kernelrelease}"

      $python_path        = 'python2.7/dist-packages'
      $cidr_package       = 'ipcalc'
      $vlan_package       = 'vlan'
      $fuel_utils_package = 'fuel-utils'

      case $::operatingsystem {
        'Debian': {
          $service_provider = undef
        }
        default: {
          $service_provider = 'upstart'
        }
      }
    }
    'RedHat': {
      $package_name       = 'openstack-neutron'
      $server_package     = false
      $server_service     = 'neutron-server'

      $ovs_agent_package  = false
      $ovs_agent_service  = 'neutron-openvswitch-agent'
      $ovs_server_package = 'openstack-neutron-openvswitch'

      $dhcp_agent_package = false
      $dhcp_agent_service = 'neutron-dhcp-agent'

      $dnsmasq_packages   = ['dnsmasq', 'dnsmasq-utils']

      $isc_dhcp_packages  = ['dhcp']

      $l3_agent_package   = false
      $l3_agent_service   = 'neutron-l3-agent'

      $cliff_package      = 'python-cliff'
      $kernel_headers     = "linux-headers-${::kernelrelease}"

      $python_path        = 'python2.6/site-packages'
      $cidr_package       = "whatmask"
      $vlan_package       = 'vconfig'
      $fuel_utils_package = 'fuel-utils'

      $service_provider   = undef

      $linuxbridge_agent_package  = 'openstack-neutron-linuxbridge'
      $linuxbridge_agent_service  = 'neutron-linuxbridge-agent'
      $linuxbridge_server_package = 'openstack-neutron-linuxbridge'
      $linuxbridge_config_file    = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'

      $metadata_agent_service = 'neutron-metadata-agent'
    }
  }
}
