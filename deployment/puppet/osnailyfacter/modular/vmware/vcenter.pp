notice('MODULAR: vmware/vcenter.pp')

$use_vcenter     = hiera('use_vcenter', false)
$vcenter_hash    = hiera('vcenter_hash')
$nova_hash       = hiera_hash('nova_hash', {})
$public_vip      = hiera('public_vip')
$use_neutron     = hiera('use_neutron', false)
$ceilometer_hash = hiera('ceilometer',{})
$debug           = hiera('debug', false)

$public_ssl_hash = hiera('public_ssl')
$vncproxy_host   = $public_ssl_hash['services'] ? {
  true    => $public_ssl_hash['hostname'],
  default => $public_vip,
}

if $use_vcenter {
  class { 'vmware':
    vcenter_settings => $vcenter_hash['computes'],
    vlan_interface   => $vcenter_hash['esxi_vlan_interface'],
    use_quantum      => $use_neutron,
    vncproxy_host    => $vncproxy_host,
    nova_hash        => $nova_hash,
    ceilometer       => $ceilometer_hash['enabled'],
    debug            => $debug,
  }
}
