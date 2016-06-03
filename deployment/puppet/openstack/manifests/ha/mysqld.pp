# == Class: openstack::ha::mysqld
#
# HA configuration for OpenStack Mysqld/Galera
#
# === Parameters
#
# [*internal_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the internal facing
#   vip
#
# [*ipaddresses*]
#   (required) Array. This is an array of ipaddresses for the backend services
#   to be loadbalanced
#
# [*public_virtual_ip*]
#   (required) String. This is the ipaddress to be used for the external facing
#   vip
#
# [*server_names*]
#   (required) Array. This is an array of server names for the haproxy service
#
# [*before_start*]
#   (optional) Boolean.
#   Defaults to false
#
# [*is_primary_controller*]
#   (optional) Boolean.
#   Defaults to false
#
class openstack::ha::mysqld (
  $internal_virtual_ip,
  $ipaddresses,
  $public_virtual_ip,
  $server_names,
  $before_start = false,
  $is_primary_controller = false,
) {

  # defaults for any haproxy_service within this class
  Openstack::Ha::Haproxy_service {
    internal_virtual_ip => $internal_virtual_ip,
    ipaddresses         => $ipaddresses,
    public_virtual_ip   => $public_virtual_ip,
    server_names        => $server_names,
  }

  openstack::ha::haproxy_service { 'mysqld':
    order                  => '110',
    listen_port            => 3306,
    balancermember_port    => 3307,
    define_backups         => true,
    haproxy_config_options => {
      'option'         => ['httpchk', 'tcplog','clitcpka','srvtcpka'],
      'mode'           => 'tcp',
      'timeout server' => '28801s',
      'timeout client' => '28801s',
      'stick-table'    => 'type ip size 1',
      'stick on'       => 'dst'
    },
    balancermember_options => 'check port 49000 inter 20s fastinter 2s downinter 2s rise 3 fall 3',
  }
}
