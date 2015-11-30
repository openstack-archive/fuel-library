notice('MODULAR: vmware/compute-vmware.pp')

$debug = hiera('debug', true)

$vcenter_hash  = hiera('vcenter', {})
$computes_hash = parse_vcenter_settings($vcenter_hash['computes'])

$uid       = hiera('uid')
$node_name = "node-$uid"
$defaults  = {
  current_node   => $node_name,
  vlan_interface => $vcenter_hash['esxi_vlan_interface']
}

create_resources(vmware::compute_vmware, $computes_hash, $defaults)


$ceilometer_hash    = hiera('ceilometer', {})
$ceilometer_enabled = $ceilometer_hash['enabled']

if $ceilometer_enabled {
  # All nova-computes services for vCenter carry same connection data to
  # vCenter. Retrieve connection settings from first service which is
  # always available.
  $computes = $vcenter_hash['computes']
  $compute = $computes[0]

  class { 'vmware::ceilometer::compute_vmware':
    availability_zone_name => $compute['availability_zone_name'],
    vc_cluster             => $compute['vc_cluster'],
    vc_host                => $compute['vc_host'],
    vc_user                => $compute['vc_user'],
    vc_password            => $compute['vc_password'],
    service_name           => $compute['service_name'],
  }
}
