notice('MODULAR: openstack-haproxy-mysqld.pp')


$mysql_hash = hiera_hash('mysql', {})
# enabled by default
$use_mysql = pick($mysql_hash['enabled'], true)

$custom_mysql_setup_class = hiera('custom_mysql_setup_class', 'galera')

# only do this if mysql is enabled and we are using one of the galera/percona
# classes
if $use_mysql and ($custom_mysql_setup_class in ['galera', 'percona', 'percona_packages']) {
  $haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                              hiera('controllers', undef))
  $server_names        = pick(hiera_array('mysqld_names', undef),
                              filter_hash($haproxy_nodes, 'name'))
  $ipaddresses         = pick(hiera_array('mysqld_ipaddresses', undef),
                              filter_hash($haproxy_nodes, 'internal_address'))
  $public_virtual_ip   = hiera('public_vip')
  $internal_virtual_ip = hiera('management_vip')

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
