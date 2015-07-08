notice('MODULAR: openstack-haproxy-nova.pp')

$haproxy_nodes       = pick(hiera('haproxy_nodes', undef),
                            hiera('controllers', undef))
$server_names        = pick(hiera_array('nova_names', undef),
                            filter_hash($haproxy_nodes, 'name'))
$ipaddresses         = pick(hiera_array('nova_ipaddresses', undef),
                            filter_hash($haproxy_nodes, 'internal_address'))
$public_virtual_ip   = hiera('public_vip')
$internal_virtual_ip = hiera('management_vip')

#$use_neutron                    = hiera('use_neutron', false)
#$ceilometer_hash                = hiera_hash('ceilometer',{})
#$sahara_hash                    = hiera_hash('sahara', {})
#$murano_hash                    = hiera_hash('murano', {})
#$storage_hash                   = hiera_hash('storage', {})
#$haproxy_nodes                  = hiera('haproxy_nodes', $controllers)

#if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
#  $use_swift = true
#} else {
#  $use_swift = false
#}

#if ($use_swift) {
#  $swift_proxies = hiera('swift_proxies', $haproxy_nodes)
#} elsif ($storage_hash['objects_ceph']) {
#  $rgw_servers = hiera('rgw_servers', $controllers)
#}

# setup ha proxy defaults
class { '::openstack::ha::haproxy':
  controllers              => $haproxy_nodes,
  public_virtual_ip        => $public_virtual_ip,
  internal_virtual_ip      => $internal_virtual_ip,
      #horizon_use_ssl          => hiera('horizon_use_ssl', false),
      #neutron                  => $use_neutron,
      #queue_provider           => 'rabbitmq',
      #custom_mysql_setup_class => hiera('custom_mysql_setup_class','galera'),
      #swift_proxies            => $swift_proxies,
      #rgw_servers              => $rgw_servers,
      #ceilometer               => $ceilometer_hash['enabled'],
      #sahara                   => $sahara_hash['enabled'],
      #murano                   => $murano_hash['enabled'],
      #is_primary_controller    => hiera('primary_controller'),
} ->

# configure nova ha proxy
class { '::openstack::ha::nova':
  server_names => $server_names,
  ipaddresses  => $ipaddresses,
}
