notice('MODULAR: vmware/vcenter.pp')

$use_vcenter     = hiera('use_vcenter', false)
$vcenter_hash    = hiera('vcenter_hash')
$public_vip      = hiera('public_vip')
$use_neutron     = hiera('use_neutron', false)
$ceilometer_hash = hiera('ceilometer',{})
$debug           = pick($vcenter_hash['debug'], hiera('debug', false))

if $use_vcenter {
  class { 'vmware':
    vcenter_settings => $vcenter_hash['computes'],
    vlan_interface   => $vcenter_hash['esxi_vlan_interface'],
    use_quantum      => $use_neutron,
    vnc_address      => $public_vip,
    ceilometer       => $ceilometer_hash['enabled'],
    debug            => $debug,
  }
}
