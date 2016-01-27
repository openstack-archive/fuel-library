notice('MODULAR: vmware/compute-vmware.pp')

$role = hiera('role')

$debug = hiera('debug', true)
$ceilometer_hash = hiera('ceilometer',{})

$vcenter_hash = hiera('vcenter', {})
$computes_hash = parse_vcenter_settings($vcenter_hash['computes'])

$defaults = {
  current_node   => hiera('node_name'),
  vlan_interface => $vcenter_hash['esxi_vlan_interface']
}

create_resources(vmware::compute_vmware, $computes_hash, $defaults)
