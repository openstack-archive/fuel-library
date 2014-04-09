class plugin_neutronnsx::params {
  $neutron_plugin_ovs_agent = 'neutron-plugin-openvswitch-agent'
  case $::osfamily {
    /(?i)debian/: {
       $neutron_plugin_package = 'neutron-plugin-vmware'
    }
    /(?i)redhat/: {
       $neutron_plugin_package = 'openstack-neutron-vmware'
       $openvswitch_package = 'openvswitch-2.0.0.30176-1.x86_64.rpm'
       $kmod_openvswitch_package = 'kmod-openvswitch-2.0.0.30176-1.el6.x86_64.rpm'
       $nicira_ovs_hypervisor_node_package = 'nicira-ovs-hypervisor-node-2.0.0.30176-1.x86_64.rpm'
    }
    default: {
      fail("Unsupported OS: ${::osfamily}/${::operatingsystem}")
    }
  }
}
