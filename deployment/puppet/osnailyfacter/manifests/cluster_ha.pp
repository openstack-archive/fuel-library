class osnailyfacter::cluster_ha {

  ##PARAMETERS DERIVED FROM YAML FILE

  if $::use_quantum {
    $novanetwork_params  = {}
    $quantum_config = sanitize_quantum_config($::fuel_settings, 'quantum_settings')
  } else {
    $quantum_hash = {}
    $quantum_params = {}
    $quantum_config = {}
    $novanetwork_params  = $::fuel_settings['novanetwork_parameters']
    $network_size         = $novanetwork_params['network_size']
    $num_networks         = $novanetwork_params['num_networks']
    $vlan_start           = $novanetwork_params['vlan_start']
  }

  if $cinder_nodes {
    $cinder_nodes_array   = $::fuel_settings['cinder_nodes']
  }
  else {
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
  $mp_hash              = $::fuel_settings['mp']
  $network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"

  if !$rabbit_hash['user'] {
    $rabbit_hash['user'] = 'nova'
  }
  $rabbit_user = $rabbit_hash['user']

  if ! $::use_quantum {
    $floating_ips_range = $::fuel_settings['floating_network_range']
  }
  $floating_hash = {}

  ##CALCULATED PARAMETERS


  ##NO NEED TO CHANGE

  $node = filter_nodes($nodes_hash,'name',$::hostname)
  if empty($node) {
    fail("Node $::hostname is not defined in the hash structure")
  }

  $vips = { # Do not convert to ARRAY, It can't work in 2.7
    public_old => {
      nic    => $::public_int,
      ip     => $::fuel_settings['public_vip'],
    },
    management_old => {
      nic    => $::internal_int,
      ip     => $::fuel_settings['management_vip'],
    },
  }

  $vip_keys = keys($vips)

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

  #$quantum_host            = $::fuel_settings['management_vip']

  ##REFACTORING NEEDED


  ##TODO: simply parse nodes array
  $controllers = merge_arrays(filter_nodes($nodes_hash,'role','primary-controller'), filter_nodes($nodes_hash,'role','controller'))
  $controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
  $controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
  $controller_storage_addresses = nodes_to_hash($controllers,'name','storage_address')
  $controller_hostnames = keys($controller_internal_addresses)
  $controller_nodes = sort(values($controller_internal_addresses))
  $controller_node_public  = $::fuel_settings['public_vip']
  $controller_node_address = $::fuel_settings['management_vip']
  $mountpoints = filter_hash($mp_hash,'point')
  $quantum_metadata_proxy_shared_secret = $quantum_config['metadata']['metadata_proxy_shared_secret']

  $quantum_gre_bind_addr = $::internal_address


  $cinder_iscsi_bind_addr = $::storage_address

  # Determine who should get the volume service
  if ($::fuel_settings['role'] == 'cinder' or $storage_hash['volumes_lvm']) {
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
    $glance_backend = 'swift'
  }

  if ($::use_ceph) {
    $primary_mons   = $controllers
    $primary_mon    = $controllers[0]['name']

    class {'ceph':
      primary_mon          => $primary_mon,
      cluster_node_address => $controller_node_public,
      use_rgw              => $storage_hash['objects_ceph'],
      use_ssl              => false,
      glance_backend       => $glance_backend,
    }
  }

  #Test to determine if swift should be enabled
  if ($storage_hash['objects_swift'] or !$storage_hash['images_ceph']) {
    $use_swift = true
  } else {
    $use_swift = false
  }

  if ($use_swift) {
    if !$::fuel_settings['swift_partition'] {
      $swift_partition = '/var/lib/glance/node'
    }
    $swift_proxies            = $controller_storage_addresses
    $swift_local_net_ip       = $::storage_address
    $master_swift_proxy_nodes = filter_nodes($nodes_hash,'role','primary-controller')
    $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['internal_address']
    #$master_hostname         = $master_swift_proxy_nodes[0]['name']
    $swift_loopback = false
    if $::fuel_settings['role'] == 'primary-controller' {
      $primary_proxy = true
    } else {
      $primary_proxy = false
    }
  }


  $network_config = {
    'vlan_start'     => $vlan_start,
  }

  if !$::fuel_settings['verbose'] {
    $verbose = false
  }

  if !$::fuel_settings['debug'] {
    $debug = false
  }

  if $::fuel_settings['role'] == 'primary-controller' {
    $primary_controller = true
  } else {
    $primary_controller = false
  }

  #HARDCODED PARAMETERS

  $multi_host              = true
  $quantum_netnode_on_cnt  = true
  $mirror_type = 'external'
  Exec { logoutput => true }




  class compact_controller (
    $quantum_network_node = $quantum_netnode_on_cnt
  ) {

    class {'osnailyfacter::apache_api_proxy':}

    class { 'openstack::controller_ha':
      controller_public_addresses   => $controller_public_addresses,
      controller_internal_addresses => $controller_internal_addresses,
      internal_address              => $internal_address,
      #internal_interface            => $::internal_int,
      public_interface              => $::public_int,
      private_interface             => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_interface']},
      internal_virtual_ip           => $::fuel_settings['management_vip'],
      public_virtual_ip             => $::fuel_settings['public_vip'],
      primary_controller            => $primary_controller,
      floating_range                => $::use_quantum ? { true=>$floating_hash, default=>false},
      fixed_range                   => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_network_range']},
      multi_host                    => $multi_host,
      network_manager               => $network_manager,
      num_networks                  => $num_networks,
      network_size                  => $network_size,
      network_config                => $network_config,
      debug                         => $debug ? { 'true'               => true, true              => true, default => false },
      verbose                       => $verbose ? { 'true'             => true, true              => true, default => false },
      queue_provider                => $::queue_provider,
      qpid_password                 => $rabbit_hash[password],
      qpid_user                     => $rabbit_hash[user],
      qpid_nodes                    => [$::fuel_settings['management_vip']],
      auto_assign_floating_ip       => $::fuel_settings['auto_assign_floating_ip'],
      mysql_root_password           => $mysql_hash[root_password],
      admin_email                   => $access_hash[email],
      admin_user                    => $access_hash[user],
      admin_password                => $access_hash[password],
      keystone_db_password          => $keystone_hash[db_password],
      keystone_admin_token          => $keystone_hash[admin_token],
      keystone_admin_tenant         => $access_hash[tenant],
      glance_db_password            => $glance_hash[db_password],
      glance_user_password          => $glance_hash[user_password],
      glance_image_cache_max_size   => $glance_hash[image_cache_max_size],
      nova_db_password              => $nova_hash[db_password],
      nova_user_password            => $nova_hash[user_password],
      rabbit_password               => $rabbit_hash[password],
      rabbit_user                   => $rabbit_hash[user],
      rabbit_nodes                  => $controller_nodes,
      memcached_servers             => $controller_nodes,
      export_resources              => false,
      glance_backend                => $glance_backend,
      swift_proxies                 => $swift_proxies,
      quantum                       => $::use_quantum,
      quantum_config                => $quantum_config,
      quantum_network_node          => $quantum_network_node,
      quantum_netnode_on_cnt        => $quantum_netnode_on_cnt,
      cinder                        => true,
      cinder_user_password          => $cinder_hash[user_password],
      cinder_iscsi_bind_addr        => $cinder_iscsi_bind_addr,
      cinder_db_password            => $cinder_hash[db_password],
      cinder_volume_group           => "cinder",
      manage_volumes                => $manage_volumes,
      galera_nodes                  => $controller_nodes,
      custom_mysql_setup_class      => $custom_mysql_setup_class,
      mysql_skip_name_resolve       => true,
      use_syslog                    => true,
      syslog_log_level              => $syslog_log_level,
      syslog_log_facility_glance   => $syslog_log_facility_glance,
      syslog_log_facility_cinder => $syslog_log_facility_cinder,
      syslog_log_facility_quantum => $syslog_log_facility_quantum,
      syslog_log_facility_nova => $syslog_log_facility_nova,
      syslog_log_facility_keystone => $syslog_log_facility_keystone,
      nova_rate_limits        => $nova_rate_limits,
      cinder_rate_limits      => $cinder_rate_limits,
      horizon_use_ssl         => $::fuel_settings['horizon_use_ssl'],
      use_unicast_corosync    => $::fuel_settings['use_unicast_corosync'],
      nameservers                   => $::dns_nameservers,
    }
  }


  class virtual_ips () {
    cluster::virtual_ips { $vip_keys:
      vips => $vips,
    }
  }



  case $::fuel_settings['role'] {
    /controller/ : {
      include osnailyfacter::test_controller

      class { '::cluster': stage => 'corosync_setup' } ->
      class { 'virtual_ips':
        stage => 'corosync_setup'
      }
      include ::haproxy::params
      class { 'cluster::haproxy':
        global_options   => merge($::haproxy::params::global_options, {'log' => "/dev/log local0"}),
        defaults_options => merge($::haproxy::params::defaults_options, {'mode' => 'http'}),
        stage            => 'cluster_head',
      }

      class { compact_controller: }
      if ($use_swift) {
        $swift_zone = $node[0]['swift_zone']

        class { 'openstack::swift::storage_node':
          storage_type          => $swift_loopback,
          loopback_size         => '5243780',
          storage_mnt_base_dir  => $swift_partition,
          storage_devices       => $mountpoints,
          swift_zone            => $swift_zone,
          swift_local_net_ip    => $storage_address,
          master_swift_proxy_ip => $master_swift_proxy_ip,
          sync_rings            => ! $primary_proxy,
          syslog_log_level      => $syslog_log_level,
          debug                 => $debug ? { 'true' => true, true => true, default=> false },
          verbose               => $verbose ? { 'true' => true, true => true, default=> false },
        }
        if $primary_proxy {
          ring_devices {'all': storages => $controllers }
        }
        class { 'openstack::swift::proxy':
          swift_user_password     => $swift_hash[user_password],
          swift_proxies           => $controller_internal_addresses,
          primary_proxy           => $primary_proxy,
          controller_node_address => $::fuel_settings['management_vip'],
          swift_local_net_ip      => $swift_local_net_ip,
          master_swift_proxy_ip   => $master_swift_proxy_ip,
          syslog_log_level        => $syslog_log_level,
          debug                   => $debug ? { 'true' => true, true => true, default=> false },
          verbose                 => $verbose ? { 'true' => true, true => true, default=> false },
        }
        if ($storage_hash['objects_swift'] or !$storage_hash['images_ceph']) {
          class { 'swift::keystone::auth':
            password         => $swift_hash[user_password],
            public_address   => $::fuel_settings['public_vip'],
            internal_address => $::fuel_settings['management_vip'],
            admin_address    => $::fuel_settings['management_vip'],
          }
        }
      }
      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images':            value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver':  value => $::fuel_settings['compute_scheduler_driver'] }

      #TODO: fix this so it dosn't break ceph
      if !($::use_ceph) {
        if $::hostname == $::fuel_settings['last_controller'] {
          class { 'openstack::img::cirros':
            os_username => shellescape($access_hash[user]),
            os_password => shellescape($access_hash[password]),
            os_tenant_name => shellescape($access_hash[tenant]),
            os_auth_url => "http://${::fuel_settings['management_vip']}:5000/v2.0/",
            img_name    => "TestVM",
            stage          => 'glance-image',
          }
        }
      }
      if ! $::use_quantum {
        nova_floating_range{ $floating_ips_range:
          ensure          => 'present',
          pool            => 'nova',
          username        => $access_hash[user],
          api_key         => $access_hash[password],
          auth_method     => 'password',
          auth_url        => "http://${::fuel_settings['management_vip']}:5000/v2.0/",
          authtenant_name => $access_hash[tenant],
        }
        Class[nova::api] -> Nova_floating_range <| |>
      }
      if ($::use_ceph){
        Class['openstack::controller'] -> Class['ceph']
      }

      #ADDONS START

      if $savanna_hash['enabled'] {
        class { 'savanna' :
          savanna_enabled       => true,
          savanna_db_password   => $savanna_hash['db_password'],
          savanna_db_host       => $controller_node_address,
          savanna_keystone_host => $controller_node_address,
          use_neutron           => $::use_quantum,
          use_floating_ips      => $bool_auto_assign_floating_ip,
        }
      }

      if $murano_hash['enabled'] {

        class { 'murano' :
          murano_enabled         => true,
          murano_rabbit_host     => $controller_node_address,
          murano_rabbit_login    => $heat_hash['rabbit_user'], # heat_hash is not mistake here
          murano_rabbit_password => $heat_hash['rabbit_password'],
          murano_db_password     => $murano_hash['db_password'],
        }

        class { 'heat' :
          heat_enabled         => true,
          heat_rabbit_host     => $controller_node_address,
          heat_rabbit_userid   => $heat_hash['rabbit_user'],
          heat_rabbit_password => $heat_hash['rabbit_password'],
          heat_db_password     => $heat_hash['db_password'],
        }

        Class['heat'] -> Class['murano']

      }

      #ADDONS END

    } #CONTROLLER ENDS

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $::public_int,
        private_interface      => $::fuel_settings['fixed_interface'],
        internal_address       => $internal_address,
        libvirt_type           => $::fuel_settings['libvirt_type'],
        fixed_range            => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_network_range']},
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => "mysql://nova:${nova_hash[db_password]}@${::fuel_settings['management_vip']}/nova",
        queue_provider         => $::queue_provider,
        qpid_password          => $rabbit_hash[password],
        qpid_user              => $rabbit_hash[user],
        qpid_nodes             => [$::fuel_settings['management_vip']],
        rabbit_nodes           => $controller_nodes,
        rabbit_password        => $rabbit_hash[password],
        rabbit_user            => $rabbit_hash[user],
        rabbit_ha_virtual_ip   => $::fuel_settings['management_vip'],
        auto_assign_floating_ip => $::fuel_settings['auto_assign_floating_ip'],
        glance_api_servers     => "${::fuel_settings['management_vip']}:9292",
        vncproxy_host          => $::fuel_settings['public_vip'],
        debug                  => $debug ? { 'true' => true, true => true, default=> false },
        verbose                => $verbose ? { 'true' => true, true => true, default=> false },
        cinder_volume_group    => "cinder",
        vnc_enabled            => true,
        manage_volumes         => $manage_volumes,
        nova_user_password     => $nova_hash[user_password],
        cache_server_ip        => $controller_nodes,
        service_endpoint       => $::fuel_settings['management_vip'],
        cinder                 => true,
        cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        db_host                => $::fuel_settings['management_vip'],
        quantum                => $::use_quantum,
        quantum_config         => $quantum_config,
        use_syslog             => true,
        syslog_log_level       => $syslog_log_level,
        syslog_log_facility    => $syslog_log_facility_nova,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        nova_rate_limits       => $nova_rate_limits,
        state_path             => $nova_hash[state_path],
      }

        if ($::use_ceph){
          Class['openstack::compute'] -> Class['ceph']
        }

#      class { "::rsyslog::client":
#        log_local => true,
#        log_auth_local => true,
#        rservers => $rservers,
#      }

      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

    } # COMPUTE ENDS

    "cinder" : {
      include keystone::python
      package { 'python-amqp':
        ensure => present
      }
      $roles = node_roles($nodes_hash, $::fuel_settings['id'])
      if member($roles, 'controller') or member($roles, 'primary-controller') {
        $bind_host = $internal_address
      } else {
        $bind_host = false
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${::fuel_settings['management_vip']}/cinder?charset=utf8",
        glance_api_servers   => "${::fuel_settings['management_vip']}:9292",
        queue_provider       => $::queue_provider,
        qpid_password        => $rabbit_hash[password],
        qpid_user            => $rabbit_hash[user],
        qpid_nodes           => [$::fuel_settings['management_vip']],
        rabbit_password      => $rabbit_hash[password],
        rabbit_host          => false,
        rabbit_nodes         => $::fuel_settings['management_vip'],
        volume_group         => 'cinder',
        manage_volumes       => $manage_volumes,
        enabled              => true,
        auth_host            => $::fuel_settings['management_vip'],
        iscsi_bind_host      => $storage_address,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $syslog_log_facility_cinder,
        syslog_log_level     => $syslog_log_level,
        debug                => $debug ? { 'true' => true, true => true, default=> false },
        verbose              => $verbose ? { 'true' => true, true => true, default=> false },
        use_syslog           => true,
      }
#      class { "::rsyslog::client":
#        log_local => true,
#        log_auth_local => true,
#        rservers => $rservers,
#      }
    } # CINDER ENDS

    "ceph-osd" : {
      #Class Ceph is already defined so it will do it's thing.
      notify {"ceph_osd: ${::ceph::osd_devices}": }
      notify {"osd_devices:  ${::osd_devices_list}": }
    } # CEPH-OSD ENDS

  } # ROLE CASE ENDS

} # CLUSTER_HA ENDS
