# Configuration of HAProxy for OpenStack
class openstack::ha::haproxy (
  $controllers,
  $public_virtual_ip,
  $internal_virtual_ip,
  $horizon_use_ssl,
  $neutron,
  $queue_provider,
  $custom_mysql_setup_class,
  $swift_proxies,
  $rgw_balancers,
  $ceilometer,
) {
  class { 'haproxy::base':  use_include => true }
  Haproxy::Service        { use_include => true }
  Haproxy::Balancermember { use_include => true }

  Openstack::Ha::Haproxy_service {
    server_names        => filter_hash($controllers, 'name')
    ipaddresses         => filter_hash($controllers, 'internal_address')
    public_virtual_ip   => $public_virtual_ip,
    internal_virtual_ip => $internal_virtual_ip,
  }

  class { 'openstack::ha::horizon': use_ssl => $horizon_use_ssl }
  class { 'openstack::ha::keystone': }
  class { 'openstack::ha::glance': }

  if $neutron { class { 'openstack::ha::neutron': } }
  if $queue_provider == 'rabbitmq' { class { 'openstack::ha::rabbitmq': } }
  if $custom_mysql_setup_class == 'galera' { class { 'openstack::ha::mysqld': } }

  if $swift_proxies { class { 'openstack::ha::swift':   servers => $swift_proxies } }
  if $rgw_servers   { class { 'openstack::ha::radosgw': servers => $rgw_servers } }
  if $ceilometer    { class { 'openstack::ha::ceilometer': } }

  Class['cluster::haproxy']       ->
  Class['openstack::ha::haproxy'] ->
  Openstack::Ha::Haproxy_service<||>
}
