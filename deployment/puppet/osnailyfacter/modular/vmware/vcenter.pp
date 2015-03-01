notice('MODULAR: vmware/vcenter.pp')

$libvirt_type = hiera('libvirt_type')
$use_vcenter = hiera('use_vcenter', false)
$vcenter_hash = hiera('vcenter_hash')
$controller_node_public = hiera('controller_node_public')
$use_neutron = hiera('use_neutron')
$ceilometer_hash = hiera('ceilometer',{})
$debug = hiera('debug', false)

# vCenter integration
if hiera('libvirt_type') == 'vcenter' {
  class { 'vmware' :
    vcenter_user            => $vcenter_hash['vc_user'],
    vcenter_password        => $vcenter_hash['vc_password'],
    vcenter_host_ip         => $vcenter_hash['host_ip'],
    vcenter_cluster         => $vcenter_hash['cluster'],
    vcenter_datastore_regex => $vcenter_hash['datastore_regex'],
    vlan_interface          => $vcenter_hash['vlan_interface'],
    use_quantum             => $use_neutron,
    vnc_address             => $controller_node_public,
    ceilometer              => $ceilometer_hash['enabled'],
    debug                   => $debug,
  }
}
# Fixme! This a temporary workaround to keep existing functioanality.
# After fully implementation of the multi HV support it is need to delete
# previos if statement
if $use_vcenter {
  class { 'vmware' :
    vcenter_settings        => $vcenter_hash['computes'],
    vlan_interface          => $vcenter_hash['vlan_interface'],
    use_quantum             => $use_neutron,
    vnc_address             => $controller_node_public,
    ceilometer              => $ceilometer_hash['enabled'],
    debug                   => $debug,
  }
}
