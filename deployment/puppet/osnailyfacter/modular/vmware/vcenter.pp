notice('MODULAR: vmware/vcenter.pp')

$use_vcenter = hiera('use_vcenter', false)
$vcenter_hash = hiera('vcenter_hash')
$controller_node_public = hiera('controller_node_public')
$use_neutron = hiera('use_neutron', false)
$ceilometer_hash = hiera('ceilometer',{})
$debug = hiera('debug', false)

if $use_vcenter {
  class { 'vmware':
    vcenter_settings => $vcenter_hash['computes'],
    vlan_interface   => $vcenter_hash['vlan_interface'],
    use_quantum      => $use_neutron,
    vnc_address      => $controller_node_public,
    ceilometer       => $ceilometer_hash['enabled'],
    debug            => $debug,
  }
}
