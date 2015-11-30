notice('MODULAR: vmware/compute-vmware.pp')

$debug = hiera('debug', true)

$vcenter_hash = hiera('vcenter', {})
$computes_hash = parse_vcenter_settings($vcenter_hash['computes'])

$uid = hiera('uid')
$node_name = "node-$uid"
$defaults = {
  current_node   => $node_name,
  vlan_interface => $vcenter_hash['esxi_vlan_interface']
}

create_resources(vmware::compute_vmware, $computes_hash, $defaults)


$ceilometer_hash = hiera('ceilometer', {})
$ceilometer_enabled = $ceilometer_hash['enabled']

if $ceilometer_enabled {
  $computes = $vcenter_hash['computes']
  $compute = $computes[0]

  $admin_address       = hiera('management_vip')
  $password            = $ceilometer_hash['user_password']
  $tenant              = pick($ceilometer_hash['tenant'], 'services')

  class { 'vmware::ceilometer::compute_vmware':
    availability_zone_name => $compute['availability_zone_name'],
    vc_cluster             => $compute['vc_cluster'],
    vc_host                => $compute['vc_host'],
    vc_user                => $compute['vc_user'],
    vc_password            => $compute['vc_password'],
    service_name           => $compute['service_name'],
    auth_uri               => "http://${admin_address}:5000",
    auth_host              => $admin_address,
    auth_user              => 'ceilometer',
    auth_password          => $password,
    tenant                 => $tenant,
  }
}
