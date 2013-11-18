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
  if !$::fuel_settings['savanna'] {
    $savanna_hash={}
  } else {
    $savanna_hash = $::fuel_settings['savanna']
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
  $rabbit_user          = $rabbit_hash['user']

  $controller = filter_nodes($nodes_hash,'role','controller')

  $controller_node_address = $controller[0]['internal_address']
  $controller_node_public = $controller[0]['public_address']


  if ($::fuel_settings['cinder']) {
    if (member($cinder_nodes_array,'all')) {
      $is_cinder_node = true
    } elsif (member($cinder_nodes_array,$::hostname)) {
      $is_cinder_node = true
    } elsif (member($cinder_nodes_array,$internal_address)) {
      $is_cinder_node = true
    } elsif ($node[0]['role'] =~ /controller/ ) {
      $is_cinder_node = member($cinder_nodes_array,'controller')
    } else {
      $is_cinder_node = member($cinder_nodes_array,$node[0]['role'])
    }
  } else {
    $is_cinder_node = false
  }


  $cinder_iscsi_bind_addr = $::storage_address

  # do not edit the below line
  validate_re($::queue_provider,  'rabbitmq|qpid')

  $sql_connection = "mysql://nova:${nova_hash[db_password]}@${controller_node_address}/nova"
  $mirror_type = 'external'
  $multi_host = true
  Exec { logoutput => true }

  $verbose = true

  if !$::fuel_settings['debug'] {
   $debug = false
  }

  # Determine who should get the volume service
  if ($::fuel_settings['role'] == 'cinder' or
      $storage_hash['volumes_lvm']
  ) {
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
      primary_mon                      => $primary_mon,
      cluster_node_address             => $controller_node_public,
      use_rgw                          => $storage_hash['objects_ceph'],
      glance_backend                   => $glance_backend,
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
        debug                   => $debug ? { 'true'=>true, true=>true, default=>false },
        verbose                 => $verbose ? { 'true'=>true, true=>true, default=>false },
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
        nova_rate_limits        => $nova_rate_limits,
        ceilometer              => $ceilometer_hash[enabled],
        ceilometer_db_password  => $ceilometer_hash[db_password],
        ceilometer_user_password => $ceilometer_hash[user_password],
        ceilometer_metering_secret => $ceilometer_hash[metering_secret],
        queue_provider          => $::queue_provider,
        rabbit_password         => $rabbit_hash[password],
        rabbit_user             => $rabbit_hash[user],
        qpid_password           => $rabbit_hash[password],
        qpid_user               => $rabbit_hash[user],
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
        use_syslog              => true,
        syslog_log_level        => $syslog_log_level,
        syslog_log_facility_glance  => $syslog_log_facility_glance,
        syslog_log_facility_cinder  => $syslog_log_facility_cinder,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_nova    => $syslog_log_facility_nova,
        syslog_log_facility_keystone=> $syslog_log_facility_keystone,
        cinder_rate_limits      => $cinder_rate_limits,
        horizon_use_ssl         => $horizon_use_ssl,
        nameservers             => $::dns_nameservers,
        primary_controller      => true,
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }
      if $::use_quantum {
        class { '::openstack::neutron_router':
          debug                 => $debug ? { 'true' => true, true => true, default=> false },
          verbose               => $verbose ? { 'true' => true, true => true, default=> false },
          # qpid_password         => $rabbit_hash[password],
          # qpid_user             => $rabbit_hash[user],
          # qpid_nodes            => [$controller_node_address],
          neutron_config          => $quantum_config,
          neutron_network_node    => true,
          use_syslog            => $use_syslog,
          syslog_log_level      => $syslog_log_level,
          syslog_log_facility   => $syslog_log_facility_quantum,
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

      if $savanna_hash['enabled'] {
        class { 'savanna' :
          savanna_api_host          => $controller_node_address,

          savanna_db_password       => $savanna_hash['db_password'],
          savanna_db_host           => $controller_node_address,

          savanna_keystone_host     => $controller_node_address,
          savanna_keystone_user     => 'admin',
          savanna_keystone_password => 'admin',
          savanna_keystone_tenant   => 'admin',

          use_neutron               => $::use_quantum,
        }
      }
        class { 'heat' :
          pacemaker              => false,
          external_ip            => $controller_node_public,

          heat_keystone_host     => $controller_node_address,
          heat_keystone_user     => 'heat',
          heat_keystone_password => 'heat',
          heat_keystone_tenant   => 'services',

          heat_rabbit_host       => $controller_node_address,
          heat_rabbit_login      => $rabbit_hash['user'],
          heat_rabbit_password   => $rabbit_hash['password'],
          heat_rabbit_port       => '5672',

          heat_db_host           => $controller_node_address,
          heat_db_password       => $heat_hash['db_password'],
        }

      if $murano_hash['enabled'] {

        class { 'murano' :
          murano_api_host          => $controller_node_address,

          murano_rabbit_host       => $controller_node_public,
          murano_rabbit_login      => 'murano',
          murano_rabbit_password   => $heat_hash['rabbit_password'],

          murano_db_host           => $controller_node_address,
          murano_db_password       => $murano_hash['db_password'],

          murano_keystone_host     => $controller_node_address,
          murano_keystone_user     => 'admin',
          murano_keystone_password => 'admin',
          murano_keystone_tenant   => 'admin',
        }

        Class['heat'] -> Class['murano']

      }

      #ADDONS END

    }

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $::public_int,
        private_interface      => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_interface'] },
        internal_address       => $internal_address,
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
        rabbit_nodes           => [$controller_node_address],
        rabbit_password        => $rabbit_hash[password],
        rabbit_user            => $rabbit_user,
        auto_assign_floating_ip => $::fuel_settings['auto_assign_floating_ip'],
        qpid_nodes             => [$controller_node_address],
        qpid_password          => $rabbit_hash[password],
        qpid_user              => $rabbit_user,
        glance_api_servers     => "${controller_node_address}:9292",
        vncproxy_host          => $controller_node_public,
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
        debug                  => $debug ? { 'true' => true, true => true, default=> false },
        verbose                => $verbose ? { 'true' => true, true => true, default=> false },
        use_syslog             => true,
        syslog_log_level       => $syslog_log_level,
        syslog_log_facility    => $syslog_log_facility_nova,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_cinder  => $syslog_log_facility_cinder,
        state_path             => $nova_hash[state_path],
        nova_rate_limits       => $nova_rate_limits,
        cinder_rate_limits     => $cinder_rate_limits
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

      if ($::use_ceph){
        Class['openstack::compute'] -> Class['ceph']
      }
    } # COMPUTE ENDS

    "cinder" : {
      include keystone::python
      package { 'python-amqp':
        ensure => present
      }
      $roles = node_roles($nodes_hash, $::fuel_settings['uid'])
      if member($roles, 'controller') or member($roles, 'primary-controller') {
        $bind_host = '0.0.0.0'
      } else {
        $bind_host = false
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${controller_node_address}/cinder?charset=utf8",
        glance_api_servers   => "${controller_node_address}:9292",
        queue_provider       => $::queue_provider,
        rabbit_password      => $rabbit_hash[password],
        rabbit_host          => false,
        bind_host            => $bind_host,
        rabbit_nodes         => [$controller_node_address],
        qpid_password        => $rabbit_hash[password],
        qpid_user            => $rabbit_hash[user],
        qpid_nodes           => [$controller_node_address],
        volume_group         => 'cinder',
        manage_volumes       => $manage_volumes,
        enabled              => true,
        auth_host            => $controller_node_address,
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $syslog_log_facility_cinder,
        syslog_log_level     => $syslog_log_level,
        debug                => $debug ? { 'true' => true, true => true, default => false },
        verbose              => $verbose ? { 'true' => true, true => true, default => false },
        use_syslog           => true,
      }
    } #CINDER ENDS

    "ceph-osd" : {
      #Nothing needs to be done Class Ceph is already defined
      notify {"ceph-osd: ${::ceph::osd_devices}": }
      notify {"osd_devices:  ${::osd_devices_list}": }
    } #CEPH_OSD ENDS

  } # ROLE CASE ENDS

} # CLUSTER_SIMPLE ENDS
# vim: set ts=2 sw=2 et :
