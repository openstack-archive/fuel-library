##############################################
#
# Need to be fixed, as master has major change
#
##############################################

notice('MODULAR: ceph/radosgw.pp')

file { '/var/lib/ceph/radosgw/ceph-radosgw.gateway':
  ensure => directory,
}

ceph::key { 'client.radosgw.gateway':
  keyring_path => '/etc/ceph/client.radosgw.gateway',
  secret  => hiera('admin_key'),
  cap_mon => 'allow rw',
  cap_osd => 'allow rwx',
  inject => true,
}

$mon_address_map  = get_node_to_ipaddr_map_by_network_role(hiera_hash('ceph_monitor_nodes'), 'ceph/public')

package{'ceph':
  ensure => installed
}

include ::tweaks::apache_wrappers
include ::ceph::params

$service_endpoint = hiera('service_endpoint')
$haproxy_stats_url = "http://${service_endpoint}:10000/;csv"

haproxy_backend_status { 'keystone-admin' :
  name  => 'keystone-2',
  count => '200',
  step  => '6',
  url   => $haproxy_stats_url,
}

haproxy_backend_status { 'keystone-public' :
  name  => 'keystone-1',
  count => '200',
  step  => '6',
  url   => $haproxy_stats_url,
}

Haproxy_backend_status['keystone-admin']  -> Ceph::Rgw::Keystone['radosgw.gateway']
Haproxy_backend_status['keystone-public'] -> Ceph::Rgw::Keystone['radosgw.gateway']

ceph::rgw { 'radosgw.gateway':
  rgw_print_continue               => true,
  keyring_path                     => '/etc/ceph/client.radosgw.gateway',
  log_file                         => '/var/log/ceph/radosgw.log',
  rgw_data                         => '/var/lib/ceph/radosgw-test',
  rgw_dns_name                     => "*.${::domain}",
}

$keystone_hash    = hiera('keystone', {})

ceph::rgw::keystone {'radosgw.gateway':
  rgw_keystone_url                 => "${service_endpoint}:35357",
  rgw_keystone_admin_token         => $keystone_hash['admin_token'],
  rgw_keystone_token_cache_size    => '10',
  rgw_keystone_accepted_roles      => '_member_, Member, admin, swiftoperator',
  rgw_keystone_revocation_interval => '1000000',
}  

Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ],
  cwd  => '/root',
}

###########################################################
# THIS SHOULD BE FIXED
# we cannot reuse this class, because it breaks our apache
###########################################################

#ceph::rgw::apache {'radosgw':
#  admin_email => 'root@localhost',
#  docroot => '/var/www/radosgw',
#  fcgi_file => '/var/www/radosgw/s3gw.fcgi',
#  rgw_dns_name => $::fqdn,
#  rgw_port => 6780,
#  rgw_socket_path => '/tmp/radosgw.sock',
#  syslog => true,
#  ceph_apache_repo => false,
#}

  class { 'osnailyfacter::apache':
    purge_configs => false,
    listen_ports  => hiera_array('apache_ports', ['0.0.0.0:80']),
  }

  include ::osnailyfacter::apache_mpm

  $admin_email     = 'root@localhost'
  $docroot         = '/var/www/radosgw'
  $fcgi_file       = '/var/www/radosgw/s3gw.fcgi'
  $rgw_dns_name    = $::fqdn
  $rgw_socket_path = '/tmp/radosgw.sock'
  $syslog          = true



  apache::vhost { "${rgw_dns_name}-radosgw":
    servername     => $rgw_dns_name,
    serveradmin    => $admin_email,
    port           => $rgw_port,
    docroot        => $docroot,
    rewrite_rule   => '^/([a-zA-Z0-9-_.]*)([/]?.*) /s3gw.fcgi?page=$1&params=$2&%{QUERY_STRING} [E=HTTP_AUTHORIZATION:%{HTTP:Authorization},L]',
    access_log     => $syslog,
    error_log      => $syslog,
    fastcgi_server => $fcgi_file,
    fastcgi_socket => $rgw_socket_path,
    fastcgi_dir    => $docroot,
  }

  # radosgw fast-cgi script
  file { $fcgi_file:
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    content => "#!/bin/sh
exec /usr/bin/radosgw -c /etc/ceph/ceph.conf -n ${name}",
  }

  File[$fcgi_file]
  ~> Service['httpd']
