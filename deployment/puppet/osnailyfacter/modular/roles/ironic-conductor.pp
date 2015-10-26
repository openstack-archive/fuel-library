notice('MODULAR: ironic/ironic-conductor.pp')

$network_scheme             = hiera('network_scheme', {})
prepare_network_config($network_scheme)
$baremetal_address          = get_network_role_property('ironic/baremetal', 'ipaddr')
$ironic_hash                = hiera_hash('ironic', {})
$management_vip             = hiera('management_vip')

$network_metadata           = hiera_hash('network_metadata', {})
$baremetal_vip              = $network_metadata['vips']['baremetal']['ipaddr']

$database_vip               = hiera('database_vip')
$service_endpoint           = hiera('service_endpoint')
$neutron_endpoint           = hiera('neutron_endpoint', $management_vip)
$glance_api_servers         = hiera('glance_api_servers', "${management_vip}:9292")
$amqp_hosts                 = hiera('amqp_hosts')
$rabbit_hosts               = split($amqp_hosts, ',')
$debug                      = hiera('debug', false)
$verbose                    = hiera('verbose', true)
$use_syslog                 = hiera('use_syslog', true)
$syslog_log_facility_ironic = hiera('syslog_log_facility_ironic', 'LOG_USER')
$rabbit_hash                = hiera_hash('rabbit_hash')
$rabbit_ha_queues           = hiera('rabbit_ha_queues')

$ironic_tenant              = pick($ironic_hash['tenant'],'services')
$ironic_user                = pick($ironic_hash['auth_name'],'ironic')
$ironic_user_password       = pick($ironic_hash['user_password'],'ironic')
$ironic_swift_tempurl_key   = pick($ironic_hash['swift_tempurl_key'],'ironic')

$db_host                    = pick($ironic_hash['db_host'], $database_vip)
$db_user                    = pick($ironic_hash['db_user'], 'ironic')
$db_name                    = pick($ironic_hash['db_name'], 'ironic')
$db_password                = pick($ironic_hash['db_password'], 'ironic')
$database_connection        = "mysql://${db_name}:${db_password}@${db_host}/${db_name}?charset=utf8&read_timeout=60"

$tftp_root                  = '/var/lib/ironic/tftpboot'

package { 'ironic-fa-deploy':
  ensure => 'present',
}

class { '::ironic':
  verbose             => $verbose,
  debug               => $debug,
  enabled_drivers     => ['fuel_ssh', 'fuel_ipmitool', 'fake'],
  rabbit_hosts        => $rabbit_hosts,
  rabbit_userid       => $rabbit_hash['user'],
  rabbit_password     => $rabbit_hash['password'],
  amqp_durable_queues => $rabbit_ha_queues,
  use_syslog          => $use_syslog,
  log_facility        => $syslog_log_facility_ironic,
  database_connection => $database_connection,
  glance_api_servers  => $glance_api_servers,
}

class { '::ironic::client': }

class { '::ironic::conductor': }

class { '::ironic::drivers::pxe':
  tftp_server      => $baremetal_address,
  tftp_root        => $tftp_root,
  tftp_master_path => "${tftp_root}/master_images",
}

ironic_config {
  'neutron/url':                          value => "http://${neutron_endpoint}:9696";
  'keystone_authtoken/auth_uri':          value => "http://${service_endpoint}:5000/";
  'keystone_authtoken/auth_host':         value => $service_endpoint;
  'keystone_authtoken/admin_tenant_name': value => $ironic_tenant;
  'keystone_authtoken/admin_user':        value => $ironic_user;
  'keystone_authtoken/admin_password':    value => $ironic_user_password, secret => true;
  'glance/swift_temp_url_key':            value => $ironic_swift_tempurl_key;
  'glance/swift_endpoint_url':            value => "http://${baremetal_vip}:8080";
  #'glance/swift_account':                value => "AUTH_${services_tenant_id}";
  'conductor/api_url':                    value => "http://${baremetal_vip}:6385";
}

file { $tftp_root:
  ensure  => directory,
  owner   => 'ironic',
  group   => 'ironic',
  mode    => '0755',
  require => Class['ironic'],
}

file { "${tftp_root}/pxelinux.0":
  ensure  => present,
  source  => '/usr/lib/syslinux/pxelinux.0',
  require => Package['syslinux'],
}

file { "${tftp_root}/map-file":
  content => "r ^([^/]) ${tftp_root}/\\1",
}

class { '::tftp':
  username  => 'ironic',
  directory => $tftp_root,
  options   => "--map-file ${tftp_root}/map-file",
  inetd     => false,
  require   => File["${tftp_root}/map-file"],
}

package { 'syslinux':
  ensure => 'present',
}

package { 'ipmitool':
  ensure => 'present',
  before => Class['::ironic::conductor'],
}

file { "/etc/ironic/fuel_key":
  ensure  => present,
  source  => '/var/lib/astute/ironic/ironic',
  owner   => 'ironic',
  group   => 'ironic',
  mode    => '0600',
  require => Class['ironic'],
}

