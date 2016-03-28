class osnailyfacter::globals::globals {

  notice('MODULAR: globals/globals.pp')

  $disable_globals_yaml = '_disabled'

  $service_token_off = false
  $globals_yaml_file = '/etc/hiera/globals.yaml'

  $base_facter_dir             = '/etc/facter'
  $facter_os_package_type_dir  = "${base_facter_dir}/facts.d"
  $facter_os_package_type_file = "${facter_os_package_type_dir}/os_package_type.txt"

  $network_scheme = hiera_hash('network_scheme', {})
  if empty($network_scheme) {
    fail('Network_scheme not given in the astute.yaml')
  }
  $network_metadata = hiera_hash('network_metadata', {})
  if empty($network_metadata) {
    fail('Network_metadata not given in the astute.yaml')
  }

  $node_key_name = get_node_key_name()
  $node_hash = $network_metadata['nodes'][$node_key_name]
  if empty($node_hash) {
    fail("Node ${node_key_name} is not defined in the network_metadata hash structure")
  }
  if empty($node_hash['fqdn']) {
    fail("Node ${node_key_name} has undefined fqdn name.")
  }
  # node_name is a short name from fqdn of node_hash. It may be changed while LCM
  # and not the same, than immutable $node_key_name
  $node_name = regsubst($node_hash['fqdn'], '\..*$', '')

  prepare_network_config($network_scheme)

  # MOS Ubuntu image uses Debian style packages. Since the introduction
  # of `$::os_package_type' fact avilable to use in project manifests,
  # we need to provide a manual override for Fuel Ubuntu images.
  if ($::osfamily == 'Debian'){
    #FIXME(mattymo): add os_package_type to hiera
    $repo_hash = hiera_hash('repo_setup')
    if $repo_hash['repo_type'] == 'uca' {
      $os_package_type_override = 'ubuntu'
    } else {
      $os_package_type_override = hiera('os_package_type', 'debian')
    }
    if (!empty($os_package_type_override)) {
      File {
        owner => 'root',
        group => 'root'
      }
      file { [$base_facter_dir, $facter_os_package_type_dir]:
        ensure => 'directory',
        mode   => '0755',
      }
      file { $facter_os_package_type_file :
        ensure  => 'present',
        mode    => '0644',
        content => "os_package_type=${os_package_type_override}\n"
      }
    }
  }

  $deployment_mode                = hiera('deployment_mode', 'ha_compact')
  $roles                          = $node_hash['node_roles']
  $storage_hash                   = hiera('storage', {})
  $syslog_hash                    = hiera('syslog', {})
  $base_syslog_hash               = hiera('base_syslog', {})
  $sahara_hash                    = hiera('sahara', {})
  $murano                         = merge({'rabbit' => {'vhost' => '/', 'port' => '55572'}},
                                          hiera('murano', {}))
  $murano_glance_artifacts_plugin = hiera('murano_glance_artifacts_plugin', {})
  $murano_hash                    = merge($murano, { 'plugins' => {'glance_artifacts_plugin' => $murano_glance_artifacts_plugin } })
  $heat_hash                      = hiera_hash('heat', {})
  $vcenter_hash                   = hiera('vcenter', {})
  $nova_hash                      = hiera_hash('nova', {})
  $mysql_hash                     = hiera('mysql', {})
  $rabbit_hash                    = hiera_hash('rabbit', {})
  $glance_hash                    = hiera_hash('glance', {})
  $swift_hash                     = hiera('swift', {})
  $cinder_hash                    = hiera_hash('cinder', {})
  $access_hash                    = hiera_hash('access', {})
  # mp_hash is actually an array, not a hash
  $mp_hash                        = hiera('mp', [])
  $keystone_hash                  = merge({'service_token_off' => $service_token_off},
                                          hiera_hash('keystone', {}))
  $neutron_hash                   = hiera_hash('neutron', {})

  $dns_nameservers                = hiera('dns_nameservers', [])
  $use_neutron                    = hiera('quantum', false)
  $use_ovs                        = hiera('use_ovs', $use_neutron)
  $verbose                        = true
  $debug                          = hiera('debug', false)
  $master_ip                      = hiera('master_ip')
  $use_syslog                     = hiera('use_syslog', true)
  $syslog_log_facility_glance     = hiera('syslog_log_facility_glance', 'LOG_LOCAL2')
  $syslog_log_facility_cinder     = hiera('syslog_log_facility_cinder', 'LOG_LOCAL3')
  $syslog_log_facility_neutron    = hiera('syslog_log_facility_neutron', 'LOG_LOCAL4')
  $syslog_log_facility_nova       = hiera('syslog_log_facility_nova','LOG_LOCAL6')
  $syslog_log_facility_keystone   = hiera('syslog_log_facility_keystone', 'LOG_LOCAL7')
  $syslog_log_facility_murano     = hiera('syslog_log_facility_murano', 'LOG_LOCAL0')
  $syslog_log_facility_heat       = hiera('syslog_log_facility_heat','LOG_LOCAL0')
  $syslog_log_facility_sahara     = hiera('syslog_log_facility_sahara','LOG_LOCAL0')
  $syslog_log_facility_ceilometer = hiera('syslog_log_facility_ceilometer','LOG_LOCAL0')
  $syslog_log_facility_ceph       = hiera('syslog_log_facility_ceph','LOG_LOCAL0')
  $syslog_log_facility_ironic     = hiera('syslog_log_facility_ironic','LOG_LOCAL0')
  $syslog_log_facility_aodh       = hiera('syslog_log_facility_aodh','LOG_LOCAL0')

  $kombu_compression              = hiera('kombu_compression', '')

  $nova_report_interval           = hiera('nova_report_interval', 60)
  $nova_service_down_time         = hiera('nova_service_down_time', 180)
  $cinder_report_interval         = hiera('cinder_report_interval', 60)
  $cinder_service_down_time       = hiera('cinder_service_down_time', 10)
  $neutron_report_interval        = hiera('neutron_report_interval', 10)
  $neutron_agent_down_time        = hiera('neutron_agent_down_time', 30)

  $custom_theme_path              = hiera('custom_theme_path', 'themes/vendor')

  $horizon_address                = pick(get_network_role_property('horizon', 'ipaddr'), '127.0.0.1')
  $apache_api_proxy_address       = get_network_role_property('admin/pxe', 'ipaddr')
  $keystone_api_address           = get_network_role_property('keystone/api', 'ipaddr')

  # Listen directives with host required for ip_based vhosts
  $apache_ports                   = hiera_array('apache_ports', unique([
                                      '127.0.0.1:80',
                                      "${horizon_address}:80",
                                      "${apache_api_proxy_address}:8888",
                                      "${keystone_api_address}:5000",
                                      "${keystone_api_address}:35357"
                                      ]))

  $token_provider                 = hiera('token_provider','keystone.token.providers.fernet.Provider')

  if ($storage_hash['volumes_ceph'] or $storage_hash['images_ceph'] or $storage_hash['objects_ceph']) {
    # Ceph is enabled
    # Define Ceph tuning settings
    $storage_tuning_settings = hiera($storage_hash['tuning_settings'], {})
    $ceph_tuning_settings = {
      'max_open_files'                       => pick($storage_tuning_settings['max_open_files'], '131072'),
      'osd_mkfs_type'                        => pick($storage_tuning_settings['osd_mkfs_type'], 'xfs'),
      'osd_mount_options_xfs'                => pick($storage_tuning_settings['osd_mount_options_xfs'], 'rw,relatime,inode64,logbsize=256k,delaylog,allocsize=4M'),
      'osd_op_threads'                       => pick($storage_tuning_settings['osd_op_threads'], '20'),
      'filestore_queue_max_ops'              => pick($storage_tuning_settings['filestore_queue_max_ops'], '500'),
      'filestore_queue_committing_max_ops'   => pick($storage_tuning_settings['filestore_queue_committing_max_ops'], '5000'),
      'journal_max_write_entries'            => pick($storage_tuning_settings['journal_max_write_entries'], '1000'),
      'journal_queue_max_ops'                => pick($storage_tuning_settings['journal_queue_max_ops'], '3000'),
      'objecter_inflight_ops'                => pick($storage_tuning_settings['objecter_inflight_ops'], '10240'),
      'filestore_queue_max_bytes'            => pick($storage_tuning_settings['filestore_queue_max_bytes'], '1048576000'),
      'filestore_queue_committing_max_bytes' => pick($storage_tuning_settings['filestore_queue_committing_max_bytes'], 1048576000),
      'journal_max_write_bytes'              => pick($storage_tuning_settings['journal_max_write_bytes'], 1048576000),
      'journal_queue_max_bytes'              => pick($storage_tuning_settings['journal_queue_max_bytes'], '1048576000'),
      'ms_dispatch_throttle_bytes'           => pick($storage_tuning_settings['ms_dispatch_throttle_bytes'], '1048576000'),
      'objecter_infilght_op_bytes'           => pick($storage_tuning_settings['objecter_infilght_op_bytes'], '1048576000'),
      'filestore_max_sync_interval'          => pick($storage_tuning_settings['filestore_max_sync_interval'], '10'),
    }
  } else {
    $ceph_tuning_settings = {}
  }

  if $debug {
    $default_log_levels = {
      'amqp'                                     => 'WARN',
      'amqplib'                                  => 'WARN',
      'boto'                                     => 'WARN',
      'qpid'                                     => 'WARN',
      'sqlalchemy'                               => 'WARN',
      'suds'                                     => 'INFO',
      'oslo_messaging'                           => 'DEBUG',
      'oslo.messaging'                           => 'DEBUG',
      'iso8601'                                  => 'WARN',
      'requests.packages.urllib3.connectionpool' => 'WARN',
      'urllib3.connectionpool'                   => 'WARN',
      'websocket'                                => 'WARN',
      'requests.packages.urllib3.util.retry'     => 'WARN',
      'urllib3.util.retry'                       => 'WARN',
      'keystonemiddleware'                       => 'WARN',
      'routes.middleware'                        => 'WARN',
      'stevedore'                                => 'WARN',
      'taskflow'                                 => 'WARN'
    }
  } else {
    $default_log_levels = {
      'amqp'                                     => 'WARN',
      'amqplib'                                  => 'WARN',
      'boto'                                     => 'WARN',
      'qpid'                                     => 'WARN',
      'sqlalchemy'                               => 'WARN',
      'suds'                                     => 'INFO',
      'oslo_messaging'                           => 'INFO',
      'oslo.messaging'                           => 'INFO',
      'iso8601'                                  => 'WARN',
      'requests.packages.urllib3.connectionpool' => 'WARN',
      'urllib3.connectionpool'                   => 'WARN',
      'websocket'                                => 'WARN',
      'requests.packages.urllib3.util.retry'     => 'WARN',
      'urllib3.util.retry'                       => 'WARN',
      'keystonemiddleware'                       => 'WARN',
      'routes.middleware'                        => 'WARN',
      'stevedore'                                => 'WARN',
      'taskflow'                                 => 'WARN'
    }
  }

  $openstack_version = hiera('openstack_version',
    {
    'keystone'   => 'installed',
    'glance'     => 'installed',
    'horizon'    => 'installed',
    'nova'       => 'installed',
    'novncproxy' => 'installed',
    'cinder'     => 'installed',
    }
  )

  $nova_rate_limits = hiera('nova_rate_limits',
    {
      'POST'         => 100000,
      'POST_SERVERS' => 100000,
      'PUT'          => 1000,
      'GET'          => 100000,
      'DELETE'       => 100000
    }
  )

  $cinder_rate_limits = hiera('cinder_rate_limits',
    {
      'POST'         => 100000,
      'POST_SERVERS' => 100000,
      'PUT'          => 100000,
      'GET'          => 100000,
      'DELETE'       => 100000
    }
  )

  $default_gateway        = get_default_gateways()
  $public_vip             = $network_metadata['vips']['public']['ipaddr']
  $management_vip         = $network_metadata['vips']['management']['ipaddr']
  $public_vrouter_vip     = $network_metadata['vips']['vrouter_pub']['ipaddr']
  $management_vrouter_vip = $network_metadata['vips']['vrouter']['ipaddr']
  $vips                   = $network_metadata['vips']

  $database_vip = is_hash($network_metadata['vips']['database']) ? {
    true    => pick($network_metadata['vips']['database']['ipaddr'], $management_vip),
    default => $management_vip
  }
  $service_endpoint = is_hash($network_metadata['vips']['service_endpoint']) ? {
    true    => pick($network_metadata['vips']['service_endpoint']['ipaddr'], $management_vip),
    default => $management_vip
  }

  if $use_neutron {
    $novanetwork_params            = {}
    $neutron_config                = hiera_hash('quantum_settings')
    $network_provider              = 'neutron'
    $neutron_db_password           = $neutron_config['database']['passwd']
    $neutron_user_password         = $neutron_config['keystone']['admin_password']
    $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
    $base_mac                      = $neutron_config['L2']['base_mac']
    $management_network_range      = get_network_role_property('mgmt/vip', 'network')
  } else {
    $neutron_config     = {}
    $novanetwork_params = hiera('novanetwork_parameters')
    $network_size       = $novanetwork_params['network_size']
    $num_networks       = $novanetwork_params['num_networks']
    $network_provider   = 'nova'
    if ( $novanetwork_params['network_manager'] == 'FlatDHCPManager') {
      $private_int                  = get_network_role_property('novanetwork/fixed', 'interface')
    } else {
      $private_int                  = get_network_role_property('novanetwork/vlan', 'interface')
      $vlan_start         = $novanetwork_params['vlan_start']
      $network_config     = {
        'vlan_start'      => $vlan_start,
      }
    }
    $network_manager          = "nova.network.manager.${novanetwork_params['network_manager']}"
    $management_network_range = hiera('management_network_range')
  }

  if roles_include('primary-controller') {
    $primary_controller = true
  } else {
    $primary_controller = false
  }

  $controller_nodes = get_nodes_hash_by_roles($network_metadata, ['primary-controller', 'controller'])
  $mountpoints      = filter_hash($mp_hash, 'point')

  # AMQP configuration
  $queue_provider   = hiera('queue_provider','rabbitmq')
  $rabbit_ha_queues = true

  if !$rabbit_hash['user'] {
    $real_rabbit_hash = merge($rabbit_hash, { 'user' => 'nova' })
  } else {
    $real_rabbit_hash = $rabbit_hash
  }

  $amqp_port  = hiera('amqp_ports', '5673')
  if hiera('amqp_hosts', false) {
    # using pre-defined in astute.yaml RabbitMQ servers
    $amqp_hosts = hiera('amqp_hosts')
  } else {
    # using RabbitMQ servers on controllers
    # todo(sv): switch from 'controller' nodes to 'rmq' nodes as soon as it was implemented as additional node-role
    $controllers_with_amqp_server = get_node_to_ipaddr_map_by_network_role($controller_nodes, 'mgmt/messaging')
    $amqp_nodes = ipsort(values($controllers_with_amqp_server))
    # amqp_hosts() randomize order of RMQ endpoints and put local one first
    $amqp_hosts = amqp_hosts($amqp_nodes, $amqp_port, get_network_role_property('mgmt/messaging', 'ipaddr'))
  }

  # Generic workers limits by RAM
  # Defines the total RAM every single worker of all service types may consume.
  # More services share the same node, more RAM ratio should be given to the workers.
  # The default value assumes there are 20 different types of workers limited by 100Mb each.
  $workers_ratio = hiera('workers_ratio', 2000)
  # Defines the maximum allowed number of workers for each service by RAM limits. Cannot exceed the value of 30.
  $workers_max = inline_template("<%= [(@memorysize_mb.to_i / @workers_ratio.to_i).floor + 1, 30].min %>")

  $node_name_prefix_for_messaging = hiera('node_name_prefix_for_messaging', 'messaging-')

  # MySQL and SQLAlchemy backend configuration
  $custom_mysql_setup_class = hiera('custom_mysql_setup_class', 'galera')
  $max_pool_size            = hiera('max_pool_size', min($::processorcount * 5 + 0, 30 + 0))
  $max_overflow             = hiera('max_overflow', min($::processorcount * 5 + 0, 60 + 0))
  $max_retries              = hiera('max_retries', '-1')
  $idle_timeout             = hiera('idle_timeout','3600')
  $nova_db_password         = $nova_hash['db_password']
  # LP#1526938 - python-mysqldb supports this, python-pymysql does not
  if $os_package_type_override == 'debian' {
    $extra_params = { 'charset' => 'utf8', 'read_timeout' => 60 }
  } else {
    $extra_params = { 'charset' => 'utf8' }
  }
  # TODO(aschultz): I don't think this is used so it should probably be
  # deprecated and removed.
  $sql_connection = os_database_connection({
    'dialect'  => 'mysql',
    'host'     => $database_vip,
    'database' => 'nova',
    'username' => 'nova',
    'password' => $nova_db_password,
    'extra'    => $extra_params
  })

  $mirror_type              = hiera('mirror_type', 'external')
  $multi_host               = hiera('multi_host', true)

  # Determine who should get the volume service
  if (member($roles, 'cinder') and $storage_hash['volumes_lvm']) {
    $manage_volumes = 'iscsi'
  } elsif (member($roles, 'cinder') and $storage_hash['volumes_vmdk']) {
    $manage_volumes = 'vmdk'
  } elsif ($storage_hash['volumes_ceph']) {
    $manage_volumes = 'ceph'
  } else {
    $manage_volumes = false
  }

  # Define ceph-related variables
  $ceph_primary_monitor_node = get_nodes_hash_by_roles($network_metadata, ['primary-controller'])
  $ceph_monitor_nodes        = $controller_nodes
  $ceph_rgw_nodes            = $controller_nodes

  #Determine who should be the default backend
  if ($storage_hash['images_ceph']) {
    $glance_backend = 'ceph'
    $glance_known_stores = [ 'glance.store.rbd.Store', 'glance.store.http.Store' ]
  } elsif ($storage_hash['images_vcenter']) {
    $glance_backend = 'vmware'
    $glance_known_stores = [ 'glance.store.vmware_datastore.Store', 'glance.store.http.Store' ]
  } else {
    $glance_backend = 'file'
    $glance_known_stores = false
  }

  # Define keystone-related variables:
  $keystone_nodes = $controller_nodes

  # Define glance-related variables:
  $glance_nodes = $controller_nodes

  # Define ceilometer-related variables:
  # todo: use special node-roles instead controllers in the future
  $ceilometer_nodes = $controller_nodes

  # Define aodh-related variables:
  # todo: use special node-roles instead controllers in the future
  $aodh_nodes = $controller_nodes

  # Define memcached-related variables:
  $memcache_roles = hiera('memcache_roles', ['primary-controller', 'controller'])

  # Define node roles, that will carry corosync/pacemaker
  $corosync_roles = hiera('corosync_roles', ['primary-controller', 'controller'])

  # Define cinder-related variables
  # todo: use special node-roles instead controllers in the future
  $cinder_nodes = $controller_nodes

  # Define horizon-related variables:
  # todo: use special node-roles instead controllers in the future
  $horizon_nodes = $controller_nodes

  # Define swift-related variables
  $swift_master_role = hiera('swift_master_role', 'primary-controller')

  # Plugins may define custom role names before this 'globals' task.
  # If no custom role are defined, the default one are used.
  $swift_object_role = hiera('swift_object_roles', ['primary-controller', 'controller'])
  $swift_nodes = get_nodes_hash_by_roles($network_metadata, $swift_object_role)

  # Plugins may define custom role names before this 'globals' task.
  # If no custom role are defined, the default one are used.
  $swift_proxy_role = hiera('swift_proxy_roles', ['primary-controller', 'controller'])
  $swift_proxies = get_nodes_hash_by_roles($network_metadata, $swift_proxy_role)

  #is_primary_swift_proxy should be override by plugin
  $is_primary_swift_proxy = $primary_controller

  # Define murano-related variables
  $murano_roles = hiera('murano_roles', ['primary-controller', 'controller'])
  $murano_nodes = get_nodes_hash_by_roles($network_metadata, $murano_roles)

  # Define heat-related variables:
  $heat_roles = hiera('heat_roles', ['primary-controller', 'controller'])
  $heat_nodes = get_nodes_hash_by_roles($network_metadata, $heat_roles)

  # Define sahara-related variable
  $sahara_roles = hiera('sahara_roles', ['primary-controller', 'controller'])
  $sahara_nodes = get_nodes_hash_by_roles($network_metadata, $sahara_roles)

  # Define ceilometer-releated parameters
  $ceilometer = hiera('ceilometer', {})
  $use_ceilometer  = $ceilometer['enabled']

  $ceilometer_defaults = {
    'alarm_history_time_to_live' => '604800',
    'event_time_to_live'         => '604800',
    'metering_time_to_live'      => '604800',
    'http_timeout'               => '600',
    'notification_driver'        => $use_ceilometer ? { true => 'messagingv2', default => $::os_service_default },
  }

  $real_ceilometer_hash = merge($ceilometer_defaults, $ceilometer)

  # Define aodh-related paramteres
  $aodh = hiera('aodh', {})

  # Define database-related variables:
  # todo: use special node-roles instead controllers in the future
  $database_nodes = $controller_nodes

  # Define Nova-API variables:
  # todo: use special node-roles instead controllers in the future
  $nova_api_nodes = $controller_nodes

  # Define mongo-related variables
  $mongo_roles = ['primary-mongo', 'mongo']

  # Define neutron-related variables:
  # todo: use special node-roles instead controllers in the future
  $neutron_nodes = $controller_nodes

  #Define Ironic-related variables:
  $ironic_api_nodes = $controller_nodes

  # Change nova_hash to add vnc port to it
  # TODO(sbog): change this when we will get rid of global hashes
  $ssl_hash = hiera_hash('use_ssl', {})
  $public_ssl_hash = hiera('public_ssl')
  $public_vnc_protocol = get_ssl_property($ssl_hash, $public_ssl_hash, 'nova', 'public', 'protocol', 'http')
  $real_nova_hash = merge($nova_hash, { 'vncproxy_protocol' => $public_vnc_protocol,
                                        'nova_rate_limits' => $nova_rate_limits,
                                        'nova_report_interval' => $nova_report_interval,
                                        'nova_service_down_time' => $nova_service_down_time,
                                        'num_networks' => $num_networks,
                                        'network_size' => $network_size,
                                        'network_manager' => $network_manager})

  $real_cinder_hash = merge($cinder_hash, { 'cinder_report_interval'   => $cinder_report_interval,
                                            'cinder_service_down_time' => $cinder_service_down_time,})

  $real_neutron_hash = merge($neutron_hash, { 'neutron_report_interval' => $neutron_report_interval,
                                              'neutron_agent_down_time' => $neutron_agent_down_time,})

  # Define how we should get memcache addresses
  if hiera('memcached_addresses', false) {
    # need this to successful lookup from template
    $memcached_addresses = hiera('memcached_addresses')
  } else {
    $memcache_nodes = get_nodes_hash_by_roles($network_metadata, $memcache_roles)
    $memcached_addresses = ipsort(values(get_node_to_ipaddr_map_by_network_role($memcache_nodes, 'mgmt/memcache')))
  }

  $cinder_backends = {
    'volumes_ceph' => $storage_hash['volumes_ceph'] ? { true => 'RBD-backend', default => false },
    'volumes_lvm' => $storage_hash['volumes_lvm'] ? { true => 'LVM-backend', default => false },
    'volumes_block_device' => $storage_hash['volumes_block_device'] ? { true => 'BDD-backend', default => false },
  }
  $storage_hash_real = merge($storage_hash, { 'volume_backend_names' => $cinder_backends })

  # save all these global variables into hiera yaml file for later use
  # by other manifests with hiera function
  file { $globals_yaml_file :
    ensure  => 'present',
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
    content => template('osnailyfacter/globals_yaml.erb')
  }

}
