notice('MODULAR: openstack-haproxy-mysqld.pp')

$mysql_hash       = hiera_hash('mysql', {})
# enabled by default
$use_mysql = pick($mysql_hash['enabled'], true)

$custom_mysql_setup_class = hiera('custom_mysql_setup_class', 'galera')

$controllers              = hiera('controllers')
$controllers_server_names = filter_hash($controllers, 'name')
$controllers_ipaddresses  = filter_hash($controllers, 'internal_address')

# only do this if mysql is enabled and we are using one of the galera/percona classes
if $use_mysql and ($custom_mysql_setup_class in ['galera', 'percona', 'percona_packages']) {
  $server_names        = pick(hiera_array('mysqld_names', undef),
                              $controllers_server_names)
  $ipaddresses         = pick(hiera_array('mysqld_ipaddresses', undef),
                              $controllers_ipaddresses)
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = pick(hiera('database_vip', undef), hiera('management_vip'))

  $primary_controller = hiera('primary_controller')


  # configure mysql ha proxy
  class { '::openstack::ha::mysqld':
    internal_virtual_ip   => $internal_virtual_ip,
    ipaddresses           => $ipaddresses,
    public_virtual_ip     => $public_virtual_ip,
    server_names          => $server_names,
    is_primary_controller => $primary_controller,
  }
}
