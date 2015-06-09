#
class neutron::params {

  if($::osfamily == 'Redhat') {
    $nobody_user_group    = 'nobody'

    $package_name       = 'openstack-neutron'
    $server_package     = false
    $server_service     = 'neutron-server'
    $client_package     = 'python-neutronclient'

    $ml2_server_package = 'openstack-neutron-ml2'

    $ovs_agent_package   = false
    $ovs_agent_service   = 'neutron-openvswitch-agent'
    $ovs_server_package  = 'openstack-neutron-openvswitch'
    $ovs_cleanup_service = 'neutron-ovs-cleanup'
    $ovs_package         = 'openvswitch'
    $libnl_package       = 'libnl'
    $package_provider    = 'rpm'

    $linuxbridge_agent_package  = false
    $linuxbridge_agent_service  = 'neutron-linuxbridge-agent'
    $linuxbridge_server_package = 'openstack-neutron-linuxbridge'
    $linuxbridge_config_file    = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'

    $cisco_server_package  = 'openstack-neutron-cisco'
    $cisco_config_file     = '/etc/neutron/plugins/cisco/cisco_plugins.ini'
    $cisco_ml2_config_file = '/etc/neutron/plugins/ml2/ml2_conf_cisco.ini'

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
    if $::operatingsystemrelease =~ /^7.*/ {
      $openswan_package     = 'libreswan'
    } else {
      $openswan_package     = 'openswan'
    }

    $l3_agent_package   = false
    $l3_agent_service   = 'neutron-l3-agent'

    $metadata_agent_service = 'neutron-metadata-agent'

    $cliff_package      = 'python-cliff'

    $kernel_headers     = "linux-headers-${::kernelrelease}"

  } elsif($::osfamily == 'Debian') {

    $nobody_user_group    = 'nogroup'

    $package_name       = 'neutron-common'
    $server_package     = 'neutron-server'
    $server_service     = 'neutron-server'
    $client_package     = 'python-neutronclient'

    if $::operatingsystem == 'Ubuntu' {
      $ml2_server_package = 'neutron-plugin-ml2'
    } else {
      $ml2_server_package = false
    }

    $ovs_agent_package   = 'neutron-plugin-openvswitch-agent'
    $ovs_agent_service   = 'neutron-plugin-openvswitch-agent'
    $ovs_server_package  = 'neutron-plugin-openvswitch'
    $ovs_cleanup_service = false
    $ovs_package         = 'openvswitch-switch'
    $libnl_package       = 'libnl1'
    $package_provider    = 'dpkg'

    $linuxbridge_agent_package  = 'neutron-plugin-linuxbridge-agent'
    $linuxbridge_agent_service  = 'neutron-plugin-linuxbridge-agent'
    $linuxbridge_server_package = 'neutron-plugin-linuxbridge'
    $linuxbridge_config_file    = '/etc/neutron/plugins/linuxbridge/linuxbridge_conf.ini'

    $cisco_server_package  = 'neutron-plugin-cisco'
    $cisco_config_file     = '/etc/neutron/plugins/cisco/cisco_plugins.ini'
    $cisco_ml2_config_file = '/etc/neutron/plugins/ml2/ml2_conf_cisco.ini'

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
}
