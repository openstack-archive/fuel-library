notice('MODULAR: openstack-haproxy-sahara.pp')

$sahara_hash     = hiera_hash('sahara',{})
# NOT enabled by default
$use_sahara      = pick($sahara_hash['enabled'], false)

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_sahara) {
  $server_names        = pick(hiera_array('sahara_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('sahara_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure sahara ha proxy
  class { '::openstack::ha::sahara':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }
}
