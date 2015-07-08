notice('MODULAR: openstack-haproxy-horizon.pp')

$horizon_hash = hiera_hash('horizon', {})
# enabled by default
$use_horizon  = pick($horizon_hash['enabled'], true)

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_horizon) {
  $server_names        = pick(hiera_array('horizon_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('horizon_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  $horizon_use_ssl     = hiera('horizon_use_ssl', false)

  # configure horizon ha proxy
  class { '::openstack::ha::horizon':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    use_ssl             => $horizon_use_ssl,
  }
}
