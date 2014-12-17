import 'globals.pp'

# vCenter integration
if hiera('libvirt_type') == 'vcenter' {
  class { 'vmware' :
    vcenter_user            => $vcenter_hash['vc_user'],
    vcenter_password        => $vcenter_hash['vc_password'],
    vcenter_host_ip         => $vcenter_hash['host_ip'],
    vcenter_cluster         => $vcenter_hash['cluster'],
    vcenter_datastore_regex => $vcenter_hash['datastore_regex'],
    vlan_interface          => $vcenter_hash['vlan_interface'],
    vnc_address             => $controller_node_public,
    use_quantum             => $use_neutron,
  }
}
