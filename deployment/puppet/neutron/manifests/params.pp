#
class neutron::params {

  if($::osfamily == 'Redhat') {
    $package_name       = 'openstack-neutron'
    $server_package     = false
    $server_service     = 'neutron-server'
    $client_package     = 'python-neutronclient'

    $ml2_server_package = 'openstack-neutron-ml2'

    $ovs_agent_package   = false
    $ovs_agent_service   = 'neutron-openvswitch-agent'
    $ovs_server_package  = 'openstack-neutron-openvswitch'
    $ovs_cleanup_service = 'neutron-ovs-cleanup'

    $linuxbridge_agent_package  = false
    $linuxbridge_agent_service  = 'neutron-linuxbridge-agent'
    $linuxbridge_server_package = 'openstack-neutron-linuxbridge'
    $linuxbridge_config_file    = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'

    $cisco_server_package = 'openstack-neutron-cisco'
    $cisco_config_file    = '/etc/neutron/plugins/cisco/cisco_plugins.ini'

    $nvp_server_package = 'openstack-neutron-nicira'

    $dhcp_agent_package = false
    $dhcp_agent_service = 'neutron-dhcp-agent'

    $dnsmasq_packages   = ['dnsmasq', 'dnsmasq-utils']

    $lbaas_agent_package = false
    $lbaas_agent_service = 'neutron-lbaas-agent'

    $haproxy_package   = 'haproxy'

    $metering_agent_package = 'openstack-neutron-metering-agent'
    $metering_agent_service = 'neutron-metering-agent'

    $vpnaas_agent_package = 'openstack-neutron-vpn-agent'
    $vpnaas_agent_service = 'neutron-vpn-agent'
    $openswan_package     = 'openswan'

    $l3_agent_package   = false
    $l3_agent_service   = 'neutron-l3-agent'

    $metadata_agent_service = 'neutron-metadata-agent'

    $cliff_package      = 'python-cliff'

    $kernel_headers     = "linux-headers-${::kernelrelease}"

  } elsif($::osfamily == 'Debian') {

    $package_name       = 'neutron-common'
    $server_package     = 'neutron-server'
    $server_service     = 'neutron-server'
    $client_package     = 'python-neutronclient'

    $ml2_server_package = false

    $ovs_agent_package   = 'neutron-plugin-openvswitch-agent'
    $ovs_agent_service   = 'neutron-plugin-openvswitch-agent'
    $ovs_server_package  = 'neutron-plugin-openvswitch'
    $ovs_cleanup_service = false

    $linuxbridge_agent_package  = 'neutron-plugin-linuxbridge-agent'
    $linuxbridge_agent_service  = 'neutron-plugin-linuxbridge-agent'
    $linuxbridge_server_package = 'neutron-plugin-linuxbridge'
    $linuxbridge_config_file    = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'

    $cisco_server_package = 'neutron-plugin-cisco'
    $cisco_config_file    = '/etc/neutron/plugins/cisco/cisco_plugins.ini'

    $nvp_server_package = 'neutron-plugin-nicira'

    $dhcp_agent_package = 'neutron-dhcp-agent'
    $dhcp_agent_service = 'neutron-dhcp-agent'

    $lbaas_agent_package = 'neutron-lbaas-agent'
    $lbaas_agent_service = 'neutron-lbaas-agent'

    $haproxy_package   = 'haproxy'

    $metering_agent_package = 'neutron-metering-agent'
    $metering_agent_service = 'neutron-metering-agent'

    $vpnaas_agent_package = 'neutron-vpn-agent'
    $vpnaas_agent_service = 'neutron-vpn-agent'

    $openswan_package     = 'openswan'

    $metadata_agent_package = 'neutron-metadata-agent'
    $metadata_agent_service = 'neutron-metadata-agent'

    $dnsmasq_packages   = ['dnsmasq-base', 'dnsmasq-utils']

    $isc_dhcp_packages  = ['isc-dhcp-server']

    $l3_agent_package   = 'neutron-l3-agent'
    $l3_agent_service   = 'neutron-l3-agent'

    $cliff_package      = 'python-cliff'
    $kernel_headers     = "linux-headers-${::kernelrelease}"

  } else {

    fail("Unsupported osfamily ${::osfamily}")

  }
  # Additional packages
  $fuel_utils_package = 'fuel-utils'
}
