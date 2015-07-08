notice('MODULAR: openstack-haproxy-murano.pp')

$murano_hash         = hiera_hash('murano',{})
# NOT enabled by default
$use_murano          = pick($murano_hash['enabled'], false)
$public_ssl_hash     = hiera('public_ssl')

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

if ($use_murano) {
  $server_names        = pick(hiera_array('murano_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('murano_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

  # configure murano ha proxy
  class { '::openstack::ha::murano':
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
    public_ssl          => $public_ssl_hash['services'],
  }
}
