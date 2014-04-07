class osnailyfacter::cluster_simple {

  if $::use_quantum {
    $novanetwork_params  = {}
    $quantum_config = sanitize_neutron_config($::fuel_settings, 'quantum_settings')
    debug__dump_to_file('/tmp/neutron_cfg.yaml', $quantum_config)
  } else {
    $quantum_config = {}
    $novanetwork_params = $::fuel_settings['novanetwork_parameters']
    $network_config = {
      'vlan_start'     => $novanetwork_params['vlan_start'],
    }
  }

  if $fuel_settings['cinder_nodes'] {
     $cinder_nodes_array   = $::fuel_settings['cinder_nodes']
  } else {
    $cinder_nodes_array = []
  }

  # All hash assignment from a dimensional hash must be in the local scope or they will
  #  be undefined (don't move to site.pp)

  #These aren't always present.
  if !$::fuel_settings['sahara'] {
    $sahara_hash={}
  } else {
    $sahara_hash = $::fuel_settings['sahara']
  }

  if !$::fuel_settings['murano'] {
    $murano_hash = {}
  } else {
    $murano_hash = $::fuel_settings['murano']
  }

  if !$::fuel_settings['heat'] {
    $heat_hash = {}
  } else {
    $heat_hash = $::fuel_settings['heat']
  }

  if !$::fuel_settings['ceilometer'] {
    $ceilometer_hash = {
      enabled => false,
      db_password => 'ceilometer',
      user_password => 'ceilometer',
      metering_secret => 'ceilometer',
    }
  } else {
    $ceilometer_hash = $::fuel_settings['ceilometer']
  }

  # vCenter integration

  if $::fuel_settings['libvirt_type'] == 'vcenter' {
    $vcenter_hash = $::fuel_settings['vcenter']
  }

  if $::fuel_settings['role'] == 'controller' {
    package { 'cirros-testvm':
      ensure => "present"
    }
  }


  $storage_hash         = $::fuel_settings['storage']
  $nova_hash            = $::fuel_settings['nova']
  $mysql_hash           = $::fuel_settings['mysql']
  $rabbit_hash          = $::fuel_settings['rabbit']
  $glance_hash          = $::fuel_settings['glance']
  $keystone_hash        = $::fuel_settings['keystone']
  $swift_hash           = $::fuel_settings['swift']
  $cinder_hash          = $::fuel_settings['cinder']
  $access_hash          = $::fuel_settings['access']
  $nodes_hash           = $::fuel_settings['nodes']
  $network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"

  if !$rabbit_hash[user] {
    $rabbit_hash[user] = 'nova'
  }

  $controller = filter_nodes($nodes_hash,'role','controller')

  $controller_node_address = $controller[0]['internal_address']
  $controller_node_public = $controller[0]['public_address']
  $roles = node_roles($nodes_hash, $::fuel_settings['uid'])

  # AMQP client configuration
  $amqp_port = '5672'
  $amqp_hosts = "${controller_node_address}:${amqp_port}"
  $rabbit_ha_queues = false

  # RabbitMQ server configuration
  $rabbitmq_bind_ip_address = 'UNSET'                 # bind RabbitMQ to 0.0.0.0
  $rabbitmq_bind_port = $amqp_port
  $rabbitmq_cluster_nodes = [$controller[0]['name']]  # has to be hostnames

  # SQLAlchemy backend configuration
  $max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
  $max_overflow = min($::processorcount * 5 + 0, 60 + 0)
  $max_retries = '-1'
  $idle_timeout = '3600'


  $cinder_iscsi_bind_addr = $::storage_address

  # do not edit the below line
  validate_re($::queue_provider,  'rabbitmq|qpid')

  $sql_connection = "mysql://nova:${nova_hash[db_password]}@${controller_node_address}/nova?read_timeout=60"
  $mirror_type = 'external'
  $multi_host = true
  Exec { logoutput => true }

  # from site.pp top scope
  $use_syslog = $::use_syslog
  $verbose = $::verbose
  $debug = $::debug

  # Determine who should get the volume service
  if (member($roles, 'cinder') and $storage_hash['volumes_lvm']) {
    $manage_volumes = 'iscsi'
  } elsif ($storage_hash['volumes_ceph']) {
    $manage_volumes = 'ceph'
  } else {
    $manage_volumes = false
  }

  #Determine who should be the default backend

  if ($storage_hash['images_ceph']) {
    $glance_backend = 'ceph'
  } else {
    $glance_backend = 'file'
  }

  if ($::use_ceph) {
    $primary_mons   = $controller
    $primary_mon    = $controller[0]['name']
    class {'ceph':
      primary_mon            => $primary_mon,
      cluster_node_address   => $controller_node_public,
      use_rgw                => $storage_hash['objects_ceph'],
      glance_backend         => $glance_backend,
      rgw_pub_ip             => $controller_node_public,
      rgw_adm_ip             => $controller_node_address,
      rgw_int_ip             => $controller_node_address,
      swift_endpoint_port    => '6780'
    }
  }

  case $::fuel_settings['role'] {
    "controller" : {
      include osnailyfacter::test_controller

      class {'osnailyfacter::apache_api_proxy':}
      class { 'openstack::controller':
        admin_address           => $controller_node_address,
        public_address          => $controller_node_public,
        public_interface        => $::public_int,
        private_interface       => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_interface']},
        internal_address        => $controller_node_address,
        service_endpoint        => $controller_node_address,
        floating_range          => false, #todo: remove as not needed ???
        fixed_range             => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_network_range'] },
        multi_host              => $multi_host,
        network_manager         => $network_manager,
        num_networks            => $::use_quantum ? { true=>false, default=>$novanetwork_params['num_networks'] },
        network_size            => $::use_quantum ? { true=>false, default=>$novanetwork_params['network_size'] },
        network_config          => $::use_quantum ? { true=>false, default=>$network_config },
        debug                   => $debug,
        verbose                 => $verbose,
        auto_assign_floating_ip => $::fuel_settings['auto_assign_floating_ip'],
        mysql_root_password     => $mysql_hash[root_password],
        admin_email             => $access_hash[email],
        admin_user              => $access_hash[user],
        admin_password          => $access_hash[password],
        keystone_db_password    => $keystone_hash[db_password],
        keystone_admin_token    => $keystone_hash[admin_token],
        keystone_admin_tenant   => $access_hash[tenant],
        glance_db_password      => $glance_hash[db_password],
        glance_user_password    => $glance_hash[user_password],
        glance_backend          => $glance_backend,
        glance_image_cache_max_size => $glance_hash[image_cache_max_size],
        nova_db_password        => $nova_hash[db_password],
        nova_user_password      => $nova_hash[user_password],
        nova_rate_limits        => $::nova_rate_limits,
        ceilometer              => $ceilometer_hash[enabled],
        ceilometer_db_password  => $ceilometer_hash[db_password],
        ceilometer_user_password => $ceilometer_hash[user_password],
        ceilometer_metering_secret => $ceilometer_hash[metering_secret],
        ceilometer_db_type      => 'mongodb',
        ceilometer_db_host      => mongo_hosts($nodes_hash),
        queue_provider          => $::queue_provider,
        amqp_hosts              => $amqp_hosts,
        amqp_user               => $rabbit_hash['user'],
        amqp_password           => $rabbit_hash['password'],
        rabbitmq_bind_ip_address => $rabbitmq_bind_ip_address,
        rabbitmq_bind_port      => $rabbitmq_bind_port,
        rabbitmq_cluster_nodes  => $rabbitmq_cluster_nodes,
        export_resources        => false,
        quantum                 => $::use_quantum,
        quantum_config          => $quantum_config,
        quantum_network_node    => $::use_quantum,
        quantum_netnode_on_cnt  => $::use_quantum,
        cinder                  => true,
        cinder_user_password    => $cinder_hash[user_password],
        cinder_db_password      => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $manage_volumes,
        use_syslog              => $use_syslog,
        novnc_address           => $controller_node_public,
        syslog_log_level        => $::syslog_log_level,
        syslog_log_facility_glance  => $::syslog_log_facility_glance,
        syslog_log_facility_cinder  => $::syslog_log_facility_cinder,
        syslog_log_facility_neutron => $::syslog_log_facility_neutron,
        syslog_log_facility_nova    => $::syslog_log_facility_nova,
        syslog_log_facility_keystone=> $::syslog_log_facility_keystone,
        cinder_rate_limits      => $::cinder_rate_limits,
        horizon_use_ssl         => $::horizon_use_ssl,
        nameservers             => $::dns_nameservers,
        primary_controller      => true,
        max_retries             => $max_retries,
        max_pool_size           => $max_pool_size,
        max_overflow            => $max_overflow,
        idle_timeout            => $idle_timeout,
        nova_report_interval    => $::nova_report_interval,
        nova_service_down_time  => $::nova_service_down_time,
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }
      if $::use_quantum {
        class { '::openstack::neutron_router':
          debug                 => $debug,
          verbose               => $verbose,
          # qpid_password         => $rabbit_hash[password],
          # qpid_user             => $rabbit_hash[user],
          # qpid_nodes            => [$controller_node_address],
          neutron_config          => $quantum_config,
          neutron_network_node    => true,
          use_syslog            => $use_syslog,
          syslog_log_level      => $::syslog_log_level,
          syslog_log_facility   => $::syslog_log_facility_neutron,
        }
      }

      class { 'openstack::auth_file':
        admin_user           => $access_hash[user],
        admin_password       => $access_hash[password],
        keystone_admin_token => $keystone_hash[admin_token],
        admin_tenant         => $access_hash[tenant],
        controller_node      => $controller_node_address,
      }

      if !$::use_quantum {
        $floating_ips_range = $::fuel_settings['floating_network_range']
        if $floating_ips_range {
          nova_floating_range{ $floating_ips_range:
            ensure          => 'present',
            pool            => 'nova',
            username        => $access_hash[user],
            api_key         => $access_hash[password],
            auth_method     => 'password',
            auth_url        => "http://${controller_node_address}:5000/v2.0/",
            authtenant_name => $access_hash[tenant],
            api_retries     => 10,
          }
        }
        Class[nova::api] -> Nova_floating_range <| |>
      }

      if ($::use_ceph){
        Class['openstack::controller'] -> Class['ceph']
      }

      #ADDONS START

      if $sahara_hash['enabled'] {
        class { 'sahara' :
          sahara_api_host            => $controller_node_address,

          sahara_db_password         => $sahara_hash['db_password'],
          sahara_db_host             => $controller_node_address,

          sahara_keystone_host       => $controller_node_address,
          sahara_keystone_user       => 'sahara',
          sahara_keystone_password   => $sahara_hash['user_password'],
          sahara_keystone_tenant     => 'services',

          use_neutron                => $::use_quantum,
          use_floating_ips           => $::fuel_settings['auto_assign_floating_ip'],

          syslog_log_facility_sahara => $syslog_log_facility_sahara,
          syslog_log_level           => $syslog_log_level,
          debug                      => $debug,
          verbose                    => $verbose,
          use_syslog                 => $use_syslog,
        }
        $scheduler_default_filters = [ 'DifferentHostFilter' ]
      } else {
        $scheduler_default_filters = []
      }

      class { '::nova::scheduler::filter':
        cpu_allocation_ratio       => '8.0',
        disk_allocation_ratio      => '1.0',
        ram_allocation_ratio       => '1.0',
        scheduler_host_subset_size => '30',
        ram_weight_multiplier      => '1.0',
        scheduler_default_filters  => concat($scheduler_default_filters, [ 'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter', 'ComputeCapabilitiesFilter', 'ImagePropertiesFilter' ])
      }

      if ($::operatingsystem != 'RedHat') {
        class { 'heat' :
          pacemaker              => false,
          external_ip            => $controller_node_public,

          keystone_host     => $controller_node_address,
          keystone_user     => 'heat',
          keystone_password => 'heat',
          keystone_tenant   => 'services',

          amqp_hosts    => $amqp_hosts,
          amqp_user     => $rabbit_hash['user'],
          amqp_password => $rabbit_hash['password'],

          db_host           => $controller_node_address,
          db_password       => $heat_hash['db_password'],

          debug               => $debug,
          verbose             => $verbose,
          use_syslog          => $use_syslog,
          syslog_log_facility => $syslog_log_facility_heat,
        }
      }

      if $murano_hash['enabled'] {

        class { 'murano' :
          murano_api_host          => $controller_node_address,

          # Murano uses two RabbitMQ - one from OpenStack and another one installed on each controller.
          #   The second instance is used for communication with agents.
          #   * murano_rabbit_host provides address for murano-engine which communicates with this
          #    'separate' rabbitmq directly (without oslo.messaging).
          #   * murano_rabbit_ha_hosts / murano_rabbit_ha_queues are required for murano-api which
          #     communicates with 'system' RabbitMQ and uses oslo.messaging.
          murano_rabbit_host       => $controller_node_public,
          murano_rabbit_ha_hosts   => $amqp_hosts,
          murano_rabbit_login      => 'murano',
          murano_rabbit_password   => $heat_hash['rabbit_password'],

          murano_db_host           => $controller_node_address,
          murano_db_password       => $murano_hash['db_password'],

          murano_keystone_host     => $controller_node_address,
          murano_keystone_user     => 'murano',
          murano_keystone_password => $murano_hash['user_password'],
          murano_keystone_tenant   => 'services',

          use_neutron              => $::use_quantum,

          use_syslog               => $use_syslog,
          debug                    => $debug,
          verbose                  => $verbose,
          syslog_log_facility      => $syslog_log_facility_murano,
        }

        Class['heat'] -> Class['murano']

      }

      # vCenter integration

      if $::fuel_settings['libvirt_type'] == 'vcenter' {

        class { 'vmware' :
          vcenter_user      => $vcenter_hash['vc_user'],
          vcenter_password  => $vcenter_hash['vc_password'],
          vcenter_host_ip   => $vcenter_hash['host_ip'],
          vcenter_cluster   => $vcenter_hash['cluster'],
          use_quantum       => $::use_quantum,
        }
      }

      #ADDONS END

    }

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $::public_int,
        private_interface      => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_interface'] },
        internal_address       => $::internal_address,
        libvirt_type           => $::fuel_settings['libvirt_type'],
        fixed_range            => $::fuel_settings['fixed_network_range'],
        network_manager        => $network_manager,
        network_config         => $::use_quantum ? { true=>false, default=>$network_config },
        multi_host             => $multi_host,
        sql_connection         => $sql_connection,
        nova_user_password     => $nova_hash[user_password],
        ceilometer              => $ceilometer_hash[enabled],
        ceilometer_metering_secret => $ceilometer_hash[metering_secret],
        ceilometer_user_password => $ceilometer_hash[user_password],
        queue_provider         => $::queue_provider,
        amqp_hosts             => $amqp_hosts,
        amqp_user              => $rabbit_hash['user'],
        amqp_password          => $rabbit_hash['password'],
        auto_assign_floating_ip => $::fuel_settings['auto_assign_floating_ip'],
        glance_api_servers     => "${controller_node_address}:9292",
        vncproxy_host          => $controller_node_public,
        vncserver_listen       => '0.0.0.0',
        vnc_enabled            => true,
        quantum                 => $::use_quantum,
        quantum_config          => $quantum_config,
        # quantum_network_node    => $::use_quantum,
        # quantum_netnode_on_cnt  => $::use_quantum,
        service_endpoint       => $controller_node_address,
        cinder                 => true,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
        cinder_volume_group    => "cinder",
        manage_volumes         => $manage_volumes,
        db_host                => $controller_node_address,
        debug                  => $debug,
        verbose                => $verbose,
        use_syslog             => $use_syslog,
        syslog_log_level       => $::syslog_log_level,
        syslog_log_facility    => $::syslog_log_facility_nova,
        syslog_log_facility_neutron => $::syslog_log_facility_neutron,
        syslog_log_facility_cinder  => $::syslog_log_facility_cinder,
        state_path             => $nova_hash[state_path],
        nova_rate_limits       => $::nova_rate_limits,
        nova_report_interval   => $::nova_report_interval,
        nova_service_down_time => $::nova_service_down_time,
        cinder_rate_limits     => $::cinder_rate_limits
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

      if ($::use_ceph){
        Class['openstack::compute'] -> Class['ceph']
      }
    } # COMPUTE ENDS

    "mongo" : {
      class { 'openstack::mongo_secondary':
        mongodb_bind_address        => [ '127.0.0.1', $::internal_address ],
        use_syslog                  => $use_syslog,
        verbose                     => $verbose,
      }
    } # MONGO ENDS

    "primary-mongo" : {
      class { 'openstack::mongo_primary':
        mongodb_bind_address        => [ '127.0.0.1', $::internal_address ],
        ceilometer_metering_secret  => $ceilometer_hash['metering_secret'],
        ceilometer_db_password      => $ceilometer_hash['db_password'],
        ceilometer_replset_members  => mongo_hosts($nodes_hash, 'array', 'mongo'),
        use_syslog                  => $use_syslog,
        verbose                     => $verbose,
      }
    } # PRIMARY-MONGO ENDS

#    "mongo" : {
#      class { 'openstack::mongo':
#        mongodb_bind_address        => [ '127.0.0.1', $::internal_address ],
#        ceilometer_metering_secret  => $ceilometer_hash['metering_secret'],
#        ceilometer_db_password      => $ceilometer_hash['db_password'],
#      }
#    } # MONGO ENDS

    "cinder" : {
      include keystone::python
      #FIXME(bogdando) notify services on python-amqp update, if needed
      package { 'python-amqp':
        ensure => present
      }
      if member($roles, 'controller') or member($roles, 'primary-controller') {
        $bind_host = '0.0.0.0'
      } else {
        $bind_host = false
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${controller_node_address}/cinder?charset=utf8&read_timeout=60",
        glance_api_servers   => "${controller_node_address}:9292",
        queue_provider       => $::queue_provider,
        amqp_hosts           => $amqp_hosts,
        amqp_user            => $rabbit_hash['user'],
        amqp_password        => $rabbit_hash['password'],
        bind_host            => $bind_host,
        volume_group         => 'cinder',
        manage_volumes       => $manage_volumes,
        enabled              => true,
        auth_host            => $controller_node_address,
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $::syslog_log_facility_cinder,
        syslog_log_level     => $::syslog_log_level,
        debug                => $debug,
        verbose              => $verbose,
        use_syslog           => $use_syslog,
        max_retries          => $max_retries,
        max_pool_size        => $max_pool_size,
        max_overflow         => $max_overflow,
        idle_timeout         => $idle_timeout,
      }
    } #CINDER ENDS

    "ceph-osd" : {
      #Nothing needs to be done Class Ceph is already defined
      notify {"ceph-osd: ${::ceph::osd_devices}": }
      notify {"osd_devices:  ${::osd_devices_list}": }
    } #CEPH_OSD ENDS

  } # ROLE CASE ENDS

  class { 'zabbix': }

} # CLUSTER_SIMPLE ENDS
# vim: set ts=2 sw=2 et :
