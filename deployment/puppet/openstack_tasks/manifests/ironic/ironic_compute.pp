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
  $debug                          = hiera('debug', false)
  $use_syslog                     = hiera('use_syslog', true)
  $use_stderr                     = hiera('use_stderr', false)
  $syslog_log_facility_ironic     = hiera('syslog_log_facility_ironic', 'LOG_LOCAL0')
  $syslog_log_facility_nova       = hiera('syslog_log_facility_nova', 'LOG_LOCAL6')
  $rabbit_hash                    = hiera_hash('rabbit')
  $nova_report_interval           = hiera('nova_report_interval', '60')
  $nova_service_down_time         = hiera('nova_service_down_time', '180')
  $neutron_config                 = hiera_hash('quantum_settings')

  $ironic_tenant                  = pick($ironic_hash['tenant'],'services')
  $ironic_username                = pick($ironic_hash['auth_name'],'ironic')
  $ironic_user_password           = pick($ironic_hash['user_password'],'ironic')

  $db_type                        = pick($nova_hash['db_type'], 'mysql+pymysql')
  $db_host                        = pick($nova_hash['db_host'], $database_vip)
  $db_user                        = pick($nova_hash['db_user'], 'nova')
  $db_name                        = pick($nova_hash['db_name'], 'nova')
  $db_password                    = pick($nova_hash['db_password'], 'nova')

  $max_pool_size = hiera('max_pool_size', min($::os_workers * 5 + 0, 30 + 0))
  $max_overflow = hiera('max_overflow', min($::os_workers * 5 + 0, 60 + 0))
  $idle_timeout = hiera('idle_timeout', '3600')
  $max_retries = hiera('max_retries', '-1')

  $max_concurrent_builds          = pick($ironic_hash['max_concurrent_builds'], 50)
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

  $notify_on_state_change         = 'vm_and_task_state'

  $ssl_hash                       = hiera_hash('use_ssl', {})
  $admin_identity_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_identity_address         = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint, $management_vip])
  $admin_identity_uri             = "${admin_identity_protocol}://${admin_identity_address}:35357"

  $glance_endpoint_default      = hiera('glance_endpoint', $management_vip)
  $glance_protocol              = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'protocol', 'http')
  $glance_endpoint              = get_ssl_property($ssl_hash, {}, 'glance', 'internal', 'hostname', $glance_endpoint_default)
  $glance_api_servers           = hiera('glance_api_servers', "${glance_protocol}://${glance_endpoint}:9292")

  $ironic_endpoint_default = hiera('ironic_endpoint', $management_vip)
  $ironic_protocol         = get_ssl_property($ssl_hash, {}, 'ironic', 'internal', 'protocol', 'http')
  $ironic_endpoint         = get_ssl_property($ssl_hash, {}, 'ironic', 'internal', 'hostname', $ironic_endpoint_default)

  $neutron_endpoint_default = hiera('neutron_endpoint', $management_vip)
  $neutron_protocol = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'protocol', 'http')
  $neutron_endpoint = get_ssl_property($ssl_hash, {}, 'neutron', 'internal', 'hostname', $neutron_endpoint_default)

  $region_name = hiera('region', 'RegionOne')

  if $nova_hash['notification_driver'] {
    $nova_notification_driver = $nova_hash['notification_driver']
  } else {
    $nova_notification_driver = []
  }

  ####### Disable upstart startup on install #######
  tweaks::ubuntu_service_override { 'nova-compute':
    package_name => 'nova-compute',
  }

  class { '::nova':
    ensure_package         => installed,
    database_connection    => $db_connection,
    default_transport_url  => $transport_url,
    image_service          => 'nova.image.glance.GlanceImageService',
    glance_api_servers     => $glance_api_servers,
    debug                  => $debug,
    use_syslog             => $use_syslog,
    use_stderr             => $use_stderr,
    notification_driver    => $nova_notification_driver,
    cinder_catalog_info    => pick($nova_hash['cinder_catalog_info'], 'volumev2:cinderv2:internalURL'),
    database_max_overflow  => $max_overflow,
    database_idle_timeout  => $idle_timeout,
    database_max_retries   => $max_retries,
    database_max_pool_size => $max_pool_size,
    log_facility           => $syslog_log_facility_nova,
    state_path             => $nova_hash['state_path'],
    report_interval        => $nova_report_interval,
    service_down_time      => $nova_service_down_time,
    notify_on_state_change => $notify_on_state_change,
    os_region_name         => $region_name,
  }

  class { '::nova::availability_zone':
    default_availability_zone => $nova_hash['default_availability_zone'],
    default_schedule_zone     => $nova_hash['default_schedule_zone'],
  }

  class { '::nova::compute':
    ensure_package            => installed,
    enabled                   => false,
    vnc_enabled               => false,
    force_config_drive        => $nova_hash['force_config_drive'],
    #NOTE(bogdando) default became true in 4.0.0 puppet-nova (was false)
    neutron_enabled           => true,
    reserved_host_memory      => '0',
    allow_resize_to_same_host => pick($nova_hash['allow_resize_to_same_host'], true)
  }

  class { '::nova::ironic::common':
    auth_url     => "${admin_identity_uri}/v2.0",
    username     => $ironic_username,
    project_name => $ironic_tenant,
    password     => $ironic_user_password,
    api_endpoint => "${ironic_protocol}://${ironic_endpoint}:6385/v1",
  }

  class { '::nova::compute::ironic':
    max_concurrent_builds => $max_concurrent_builds
  }

  class { '::nova::network::neutron':
    neutron_admin_password => $neutron_config['keystone']['admin_password'],
    neutron_url            => "${neutron_protocol}://${neutron_endpoint}:9696",
    neutron_admin_auth_url => "${admin_identity_uri}/v3",
  }

  # Remove this once nova package is updated and contains
  # use_neutron set to true by default LP #1668623
  ensure_resource('nova_config', 'DEFAULT/use_neutron', {'value' => true })

  pcmk_resource { 'p_nova_compute_ironic':
    ensure             => 'present',
    primitive_class    => 'ocf',
    primitive_provider => 'fuel',
    primitive_type     => 'nova-compute',
    metadata           => {
      'resource-stickiness' => '1'
    },
    parameters         => {
      'config'                => "/etc/nova/nova.conf",
      'pid'                   => "/var/run/nova/nova-compute-ironic.pid",
      'additional_parameters' => "--config-file=/etc/nova/nova-compute.conf",
    },
    operations         => {
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
