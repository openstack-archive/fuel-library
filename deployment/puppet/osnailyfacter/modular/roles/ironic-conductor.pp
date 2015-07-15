notice('MODULAR: ironic-conductor.pp')

$ironic_hash                = hiera('ironic')
$management_vip             = hiera('management_vip')
$baremetal_vip              = hiera('baremetal_vip')
$service_endpoint           = hiera('service_endpoint', $management_vip)
$database_vip               = hiera('database_vip', $service_endpoint)
$keystone_endpoint          = hiera('keystone_endpoint', $service_endpoint)
$neutron_endpoint           = hiera('neutron_endpoint', $service_endpoint)
$glance_api_servers         = hiera('glance_api_servers', "${service_endpoint}:9292")
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_hosts               = split($amqp_hosts, ',')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$syslog_log_facility_ironic = hiera('syslog_log_facility_ironic', 'LOG_USER')
$rabbit_hash                = hiera('rabbit_hash')
$rabbit_ha_queues           = hiera('rabbit_ha_queues')

$network_scheme             = hiera('network_scheme', {})
prepare_network_config($network_scheme)
$baremetal_address          = get_network_role_property('baremetal', 'ipaddr')

$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['user'],'ironic')
$ironic_user_password       = $ironic_hash['user_password']
$ironic_swift_tempurl_key   = $ironic_hash['swift_tempurl_key']

$db_host                    = pick($ironic_hash['db_host'], $database_vip)
$db_user                    = pick($ironic_hash['db_user'], 'ironic')
$db_name                    = pick($ironic_hash['db_name'], 'ironic')
$db_password                = pick($ironic_hash['db_password'], 'ironic')
$database_connection        = "mysql://${db_name}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$tftp_root                  = "/var/lib/ironic/tftpboot"

class { 'ironic':
  verbose                   => $verbose,
  debug                     => $debug,
  enabled_drivers           => ['fuel_ssh'],
  rabbit_hosts              => $rabbit_hosts,
  rabbit_port               => 5673,
  rabbit_userid             => $rabbit_hash['user'],
  rabbit_password           => $rabbit_hash['password'],
  amqp_durable_queues       => $rabbit_ha_queues,
  use_syslog                => $use_syslog,
  log_facility              => $syslog_log_facility_ironic,
  database_connection       => $database_connection,
  glance_api_servers        => $glance_api_servers,
}

class { 'ironic::client': }

class { 'ironic::conductor': }

ironic_config {
  'neutron/url':                          value => "http://${neutron_endpoint}:9696";
  'keystone_authtoken/auth_uri':          value => "http://${keystone_endpoint}:5000/";
  'keystone_authtoken/auth_host':         value => $keystone_endpoint;
  'keystone_authtoken/admin_tenant_name': value => $ironic_tenant;
  'keystone_authtoken/admin_user':        value => $ironic_user;
  'keystone_authtoken/admin_password':    value => $ironic_user_password, secret => true;
  'pxe/tftp_server':                      value => $baremetal_address;
  'pxe/tftp_root':                        value => $tftp_root;
  'pxe/tftp_master_path':                 value => "${tftp_root}/master_images";
  'glance/swift_temp_url_key':            value => $ironic_swift_tempurl_key;
  'glance/swift_endpoint_url':            value => "http://${baremetal_vip}:8080";
  #'glance/swift_account':                value => "AUTH_${services_tenant_id}";
  'conductor/api_url':                    value => "${baremetal_vip}:6385";
}

file { $tftp_root:
  ensure => directory,
  owner => 'ironic',
  group => 'ironic',
  mode => 755,
  require => Class['ironic'],
}

file { "${tftp_root}/pxelinux.0":
  ensure => present,
  source => '/usr/lib/syslinux/pxelinux.0',
  require => Package['syslinux'],
}

file { "${tftp_root}/map-file":
  content => "r ^([^/]) ${tftp_root}/\\1",
  notify  => Service['tftpd-hpa'], 
}

file { '/etc/default/tftpd-hpa':
  content => "TFTP_USERNAME='tftp' \nTFTP_DIRECTORY='${tftp_root}' \nTFTP_ADDRESS='[::]:69' \nTFTP_OPTIONS='--map-file ${tftp_root}/map-file' \n",
  require => Package['tftpd-hpa'],
  notify  => Service['tftpd-hpa'],
}

package { 'tftpd-hpa':
  ensure => 'present',
}

package { 'syslinux':
  ensure => 'present',
}

service { 'tftpd-hpa' :
  ensure     => 'running',
  enable     => true,
  require    => File[$tftp_root],
}

firewall { '208 ironic-tftpd' :
  dport   => '69',
  proto   => 'udp',
  action  => 'accept',
}
