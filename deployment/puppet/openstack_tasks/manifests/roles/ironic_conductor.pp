class openstack_tasks::roles::ironic_conductor {

  notice('MODULAR: roles/ironic_conductor.pp')

  $network_scheme = hiera_hash('network_scheme', {})
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
  $verbose                    = hiera('verbose', undef)
  $use_syslog                 = hiera('use_syslog', true)
  $syslog_log_facility_ironic = hiera('syslog_log_facility_ironic', 'LOG_USER')
  $rabbit_hash                = hiera_hash('rabbit')
  $amqp_durable_queues        = pick($ironic_hash['amqp_durable_queues'], false)
  $storage_hash               = hiera('storage')
  $kombu_compression          = hiera('kombu_compression', '')

  $ironic_tenant              = pick($ironic_hash['tenant'],'services')
  $ironic_user                = pick($ironic_hash['auth_name'],'ironic')
  $ironic_user_password       = pick($ironic_hash['user_password'],'ironic')
  $ironic_swift_tempurl_key   = pick($ironic_hash['swift_tempurl_key'],'ironic')

  $db_type                    = pick($ironic_hash['db_type'], 'mysql+pymysql')
  $db_host                    = pick($ironic_hash['db_host'], $database_vip)
  $db_user                    = pick($ironic_hash['db_user'], 'ironic')
  $db_name                    = pick($ironic_hash['db_name'], 'ironic')
  $db_password                = pick($ironic_hash['db_password'], 'ironic')
  case $db_type {
    'mysql': { $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }}
    'mysql+pymysql': { $extra_params = { 'charset' => 'utf8' }}
  }
  $db_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

  $tftp_root                  = '/var/lib/ironic/tftpboot'

  $temp_url_endpoint_type = $storage_hash['images_ceph'] ? {
    true    => 'radosgw',
    default => 'swift'
  }

  package { 'ironic-fa-deploy':
    ensure => 'present',
  }

  if $verbose {
    warning('The $verbose is deprecated and will be removed in a future release')
  }

  class { '::ironic':
    verbose              => $verbose,
    debug                => $debug,
    enabled_drivers      => ['fuel_ssh', 'fuel_ipmitool', 'fake', 'fuel_libvirt'],
    rabbit_hosts         => $rabbit_hosts,
    rabbit_userid        => $rabbit_hash['user'],
    rabbit_password      => $rabbit_hash['password'],
    amqp_durable_queues  => $amqp_durable_queues,
    control_exchange     => 'ironic',
    use_syslog           => $use_syslog,
    log_facility         => $syslog_log_facility_ironic,
    database_connection  => $db_connection,
    database_max_retries => '-1',
    sync_db              => false,
    glance_api_servers   => $glance_api_servers,
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
    'glance/temp_url_endpoint_type':        value => $temp_url_endpoint_type;
    'conductor/api_url':                    value => "http://${baremetal_vip}:6385";
  }

  if !defined(Ironic_config['oslo_messaging_rabbit/heartbeat_timeout_threshold']) {
    ironic_config { 'oslo_messaging_rabbit/heartbeat_timeout_threshold': value => $::os_service_default; }
  }
  if !defined(Ironic_config['oslo_messaging_rabbit/heartbeat_rate']) {
    ironic_config { 'oslo_messaging_rabbit/heartbeat_rate': value => $::os_service_default; }
  }

  # TODO (iberezovskiy): remove this workaround in N when ironic module
  # will be switched to puppet-oslo usage for rabbit configuration
  if $kombu_compression in ['gzip','bz2'] {
    if !defined(Oslo::Messaging_rabbit['ironic_config']) and !defined(Ironic_config['oslo_messaging_rabbit/kombu_compression']) {
      ironic_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
    } else {
      Ironic_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
    }
  }

  file { $tftp_root:
    ensure  => directory,
    owner   => 'ironic',
    group   => 'ironic',
    mode    => '0755',
    require => Class['::ironic'],
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

  file { '/etc/ironic/fuel_key':
    ensure  => present,
    source  => '/var/lib/astute/ironic/ironic',
    owner   => 'ironic',
    group   => 'ironic',
    mode    => '0600',
    require => Class['::ironic'],
  }

}
