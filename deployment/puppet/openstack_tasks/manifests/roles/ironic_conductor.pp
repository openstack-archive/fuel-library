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
  $kombu_compression          = hiera('kombu_compression', $::os_service_default)

  $ironic_tenant              = pick($ironic_hash['tenant'],'services')
  $ironic_user                = pick($ironic_hash['auth_name'],'ironic')
  $ironic_user_password       = pick($ironic_hash['user_password'],'ironic')
  $ironic_swift_tempurl_key   = pick($ironic_hash['swift_tempurl_key'],'ironic')
  $memcached_servers          = hiera('memcached_servers')
  $local_memcached_server = hiera('local_memcached_server')

  $ssl_hash                   = hiera('use_ssl', {})
  $neutron_endpoint_default   = hiera('neutron_endpoint', $management_vip)
  $neutron_protocol           = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
  $neutron_endpoint           = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', $neutron_endpoint_default)
  $neutron_uri                = "${neutron_protocol}://${neutron_endpoint}:9696"
  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_address      = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint, $management_vip])
  $internal_auth_uri          = "${internal_auth_protocol}://${internal_auth_address}:5000"
  $admin_identity_protocol    = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address     = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_uri         = "${admin_identity_protocol}://${admin_identity_address}:35357"

  $db_type                    = pick($ironic_hash['db_type'], 'mysql+pymysql')
  $db_host                    = pick($ironic_hash['db_host'], $database_vip)
  $db_user                    = pick($ironic_hash['db_user'], 'ironic')
  $db_name                    = pick($ironic_hash['db_name'], 'ironic')
  $db_password                = pick($ironic_hash['db_password'], 'ironic')
  # LP#1526938 - python-mysqldb supports this, python-pymysql does not
  if $::os_package_type == 'debian' {
    $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
  } else {
    $extra_params = { 'charset' => 'utf8' }
  }
  $db_connection = os_database_connection({
    'dialect'  => $db_type,
    'host'     => $db_host,
    'database' => $db_name,
    'username' => $db_user,
    'password' => $db_password,
    'extra'    => $extra_params
  })

  $transport_url = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')

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

  class { '::ironic::neutron':
    api_endpoint => $neutron_uri,
    auth_url     => $admin_identity_uri,
    project_name => $ironic_tenant,
    username     => $ironic_user,
    password     => $ironic_user_password,
  }

  class { '::ironic':
    debug                 => $debug,
    default_transport_url => $transport_url,
    amqp_durable_queues   => $amqp_durable_queues,
    control_exchange      => 'ironic',
    use_syslog            => $use_syslog,
    log_facility          => $syslog_log_facility_ironic,
    database_connection   => $db_connection,
    database_max_retries  => '-1',
    sync_db               => false,
    glance_api_servers    => $glance_api_servers,
    kombu_compression     => $kombu_compression,
  }

  class { '::ironic::client': }

  class { '::ironic::conductor':
    api_url                   => "http://${baremetal_vip}:6385",
    enabled_drivers           => ['fuel_ssh', 'fuel_ipmitool', 'fake', 'fuel_libvirt'],
    swift_temp_url_key        => $ironic_swift_tempurl_key,
    cleaning_network_name     => 'baremetal',
    provisioning_network_name => 'baremetal',

  }

  class { '::ironic::drivers::interfaces':
    enabled_network_interfaces => ['noop', 'flat', 'neutron']
  }

  class { '::ironic::drivers::pxe':
    tftp_server      => $baremetal_address,
    tftp_root        => $tftp_root,
    tftp_master_path => "${tftp_root}/master_images",
  }

  ironic_config {
    'keystone_authtoken/auth_uri':          value => $internal_auth_uri;
    'keystone_authtoken/identity_uri':      value => $admin_identity_uri;
    'keystone_authtoken/admin_tenant_name': value => $ironic_tenant;
    'keystone_authtoken/admin_user':        value => $ironic_user;
    'keystone_authtoken/admin_password':    value => $ironic_user_password, secret => true;
    'keystone_authtoken/memcached_servers': value => $local_memcached_server;
    'glance/swift_endpoint_url':            value => "http://${baremetal_vip}:8080";
    'glance/temp_url_endpoint_type':        value => $temp_url_endpoint_type;
  }

  file { $tftp_root:
    ensure  => directory,
    owner   => 'ironic',
    group   => 'ironic',
    mode    => '0755',
    source  => "/usr/lib/syslinux/modules/bios/",
    recurse => true,
    require => [Class['::ironic'], Package['syslinux-common']],
  }

  # TODO(vsaienko) remove provider hack when puppetlabs-tftp fixed issue with
  # default provider.
  Service <| title == 'tftpd-hpa' |> { provider => 'systemd'}

  ensure_packages(['syslinux', 'pxelinux', syslinux-common], {
    ensure => 'present',
    before => File["${tftp_root}/pxelinux.0"]
  })

  file { "${tftp_root}/pxelinux.0":
    ensure => present,
    source => '/usr/lib/PXELINUX/pxelinux.0',
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

  # TODO(mpolenchuk): remove it once this package have installed by dependency
  ensure_packages('open-iscsi')

  file { '/etc/ironic/fuel_key':
    ensure  => present,
    source  => '/var/lib/astute/ironic/ironic',
    owner   => 'ironic',
    group   => 'ironic',
    mode    => '0600',
    require => Class['::ironic'],
  }

}
