class openstack_tasks::ironic::ironic_compute {

  #####################################################################################
  ###  ironic-compute is additional compute role with compute_driver=ironic.        ###
  ###  It can't be assigned with nova-compute to the same node. It doesn't include  ###
  ###  openstack::compute class it is configured separately.                        ###
  #####################################################################################

  notice('MODULAR: ironic/ironic_compute.pp')

  $ironic_hash                    = hiera_hash('ironic', {})
  $nova_hash                      = hiera_hash('nova', {})
  $management_vip                 = hiera('management_vip')
  $database_vip                   = hiera('database_vip')
  $service_endpoint               = hiera('service_endpoint')
  $neutron_endpoint               = hiera('neutron_endpoint', $management_vip)
  $ironic_endpoint                = hiera('ironic_endpoint', $management_vip)
  $glance_api_servers             = hiera('glance_api_servers', "${management_vip}:9292")
  $debug                          = hiera('debug', false)
  $verbose                        = hiera('verbose', true)
  $use_syslog                     = hiera('use_syslog', true)
  $syslog_log_facility_ironic     = hiera('syslog_log_facility_ironic', 'LOG_LOCAL0')
  $syslog_log_facility_nova       = hiera('syslog_log_facility_nova', 'LOG_LOCAL6')
  $amqp_hosts                     = hiera('amqp_hosts')
  $rabbit_hash                    = hiera_hash('rabbit')
  $nova_report_interval           = $nova_hash['nova_report_interval']
  $nova_service_down_time         = $nova_hash['nova_service_down_time']
  $neutron_config                 = hiera_hash('quantum_settings')

  $ironic_tenant                  = pick($ironic_hash['tenant'],'services')
  $ironic_username                = pick($ironic_hash['auth_name'],'ironic')
  $ironic_user_password           = pick($ironic_hash['user_password'],'ironic')

  $db_type                        = 'mysql'
  $db_host                        = pick($nova_hash['db_host'], $database_vip)
  $db_user                        = pick($nova_hash['db_user'], 'nova')
  $db_name                        = pick($nova_hash['db_name'], 'nova')
  $db_password                    = pick($nova_hash['db_password'], 'nova')
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

  $memcached_servers              = hiera('memcached_addresses')
  $memcached_port                 = hiera('memcache_server_port', '11211')
  $memcached_addresses            = suffix($memcached_servers, ":${memcached_port}")
  $notify_on_state_change         = 'vm_and_task_state'

  $ssl_hash                       = hiera_hash('use_ssl', {})
  $admin_identity_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_uri             = "${admin_identity_protocol}://${admin_identity_address}:35357"

  ####### Disable upstart startup on install #######
  tweaks::ubuntu_service_override { 'nova-compute':
    package_name => 'nova-compute',
  }

  class { '::nova':
      install_utilities      => false,
      ensure_package         => installed,
      database_connection    => $db_connection,
      rpc_backend            => 'nova.openstack.common.rpc.impl_kombu',
      #FIXME(bogdando) we have to split amqp_hosts until all modules synced
      rabbit_hosts           => split($amqp_hosts, ','),
      rabbit_userid          => $rabbit_hash['user'],
      rabbit_password        => $rabbit_hash['password'],
      image_service          => 'nova.image.glance.GlanceImageService',
      glance_api_servers     => $glance_api_servers,
      verbose                => $verbose,
      debug                  => $debug,
      use_syslog             => $use_syslog,
      log_facility           => $syslog_log_facility_nova,
      state_path             => $nova_hash['state_path'],
      report_interval        => $nova_report_interval,
      service_down_time      => $nova_service_down_time,
      notify_on_state_change => $notify_on_state_change,
      memcached_servers      => $memcached_addresses,
  }

  class { '::nova::compute':
    ensure_package            => installed,
    enabled                   => false,
    vnc_enabled               => false,
    force_config_drive        => $nova_hash['force_config_drive'],
    #NOTE(bogdando) default became true in 4.0.0 puppet-nova (was false)
    neutron_enabled           => true,
    default_availability_zone => $nova_hash['default_availability_zone'],
    default_schedule_zone     => $nova_hash['default_schedule_zone'],
    reserved_host_memory      => '0',
    compute_manager           => 'ironic.nova.compute.manager.ClusteredComputeManager',
  }

  class { '::nova::compute::ironic':
    admin_url                 => "${admin_identity_uri}/v2.0",
    admin_username            => $ironic_username,
    admin_tenant_name         => $ironic_tenant,
    admin_password            => $ironic_user_password,
    api_endpoint              => "http://${ironic_endpoint}:6385/v1",
    max_concurrent_builds     => 50
  }

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_config['keystone']['admin_password'],
    neutron_url            => "http://${neutron_endpoint}:9696",
    neutron_admin_auth_url => "${admin_identity_uri}/v3",
  }

  pcmk_resource { 'p_nova_compute_ironic':
    ensure             => 'present',
    primitive_class    => 'ocf',
    primitive_provider => 'fuel',
    primitive_type     => 'nova-compute',
    metadata        => {
      'resource-stickiness' => '1'
    },
    parameters      => {
      'config'                => "/etc/nova/nova.conf",
      'pid'                   => "/var/run/nova/nova-compute-ironic.pid",
      'additional_parameters' => "--config-file=/etc/nova/nova-compute.conf",
    },
    operations      => {
      monitor  => { 'timeout' => '30', 'interval' => '60' },
      start    => { 'timeout' => '30' },
      stop     => { 'timeout' => '30' }
    }
  }

  service { 'p_nova_compute_ironic':
    ensure   => running,
    enable   => true,
    provider => 'pacemaker',
  }

  file { '/etc/nova/nova-compute.conf':
    content => "[DEFAULT]\nhost=ironic-compute",
    require => Package['nova-compute'],
  } ~> Service['p_nova_compute_ironic']

}
