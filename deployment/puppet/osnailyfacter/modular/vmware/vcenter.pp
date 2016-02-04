notice('MODULAR: vmware/vcenter.pp')

$use_vcenter       = hiera('use_vcenter', false)
$vcenter_hash      = hiera('vcenter_hash')
$public_vip        = hiera('public_vip')
$use_neutron       = hiera('use_neutron', false)
$ceilometer_hash   = hiera('ceilometer',{})
$nova_hash         = hiera_hash('nova_hash', {})
$public_ssl_hash   = hiera('public_ssl')
$ssl_hash          = hiera_hash('use_ssl', {})
$vncproxy_protocol = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', [$nova_hash['vncproxy_protocol'], 'http'])
$vncproxy_host     = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'hostname', [$public_vip])
$debug             = pick($vcenter_hash['debug'], hiera('debug', false))

if $use_vcenter {
  class { 'vmware':
    vcenter_settings  => $vcenter_hash['computes'],
    vlan_interface    => $vcenter_hash['esxi_vlan_interface'],
    use_quantum       => $use_neutron,
    vncproxy_protocol => $vncproxy_protocol,
    vncproxy_host     => $vncproxy_host,
    nova_hash         => $nova_hash,
    ceilometer        => $ceilometer_hash['enabled'],
    debug             => $debug,
  }
}
