notice('MODULAR: openstack-haproxy-ceilometer.pp')

$ceilometer_hash     = hiera_hash('ceilometer',{})
# NOT enabled by default
$use_ceilometer      = pick($ceilometer_hash['enabled'], false)

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_ceilometer) {
  $server_names        = pick(hiera_array('ceilometer_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('ceilometer_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure ceilometer ha proxy
  class { '::openstack::ha::ceilometer':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
