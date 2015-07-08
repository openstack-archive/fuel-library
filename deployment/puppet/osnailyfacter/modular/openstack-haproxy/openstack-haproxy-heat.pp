notice('MODULAR: openstack-haproxy-heat.pp')

$heat_hash = hiera_hash('heat', {})
# enabled by default
$use_heat = pick($heat_hash['enabled'], true)
$public_ssl_hash = hiera('public_ssl')

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_heat) {
  $server_names        = pick(hiera_array('heat_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('heat_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

# configure heat ha proxy
  class { '::openstack::ha::heat':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl    => $public_ssl_hash['services'],
  }
}
