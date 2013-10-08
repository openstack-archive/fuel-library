class osnailyfacter::cluster_simple {

	if $::use_quantum
	{
	  $quantum_hash   = $::fuel_settings['quantum_access']
	  $quantum_params = $::fuel_settings['quantum_parameters']
	  $novanetwork_params  = {}
	} else {
	  $quantum_hash = {}
	  $quantum_params = {}
	  $novanetwork_params  = $::fuel_settings['novanetwork_parameters']
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
	$vlan_start           = $novanetwork_params['vlan_start']
	$network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"
	$network_size         = $novanetwork_params['network_size']
	$num_networks         = $novanetwork_params['num_networks']
	$tenant_network_type  = $quantum_params['tenant_network_type']
	$segment_range        = $quantum_params['segment_range']

	if !$rabbit_hash[user] {
	  $rabbit_hash[user] = 'nova'
	}
  $rabbit_user          = $rabbit_hash['user']


	if $::use_quantum {
	   $floating_hash = $::fuel_settings['floating_network_range']
	} else {
	  $floating_hash = {}
	  $floating_ips_range = $::fuel_settings['floating_network_range']
  }

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
	
	$network_config = {
	  'vlan_start'     => $vlan_start,
	}
	$sql_connection           = "mysql://nova:${nova_hash[db_password]}@${controller_node_address}/nova"
	$mirror_type = 'external'
	$multi_host              = true
	Exec { logoutput => true }
	
	$quantum_host            = $controller_node_address
	$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"
	$quantum_metadata_proxy_shared_secret = $quantum_params['metadata_proxy_shared_secret']
	$quantum_gre_bind_addr = $::internal_address

	if !$::fuel_settings['verbose'] {
	 $verbose = false
	}
	
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
	    primary_mon          => $primary_mon,
	    cluster_node_address => $controller_node_public,
	    use_rgw              => $storage_hash['objects_ceph'],
	    use_ssl              => false,
	    glance_backend       => $glance_backend,
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
        private_interface       => $::fuel_settings['fixed_interface'],
        internal_address        => $controller_node_address,
        floating_range          => $::use_quantum ? { 'true' =>$floating_hash, default=>false},
        fixed_range             => $::fuel_settings['fixed_network_range'],
        multi_host              => $multi_host,
        network_manager         => $network_manager,
        num_networks            => $num_networks,
        network_size            => $network_size,
        network_config          => $network_config,
        debug                   => $debug ? { 'true' => true, true => true, default=> false },
        verbose                 => $verbose ? { 'true' => true, true => true, default=> false },
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
        queue_provider          => $::queue_provider,
        rabbit_password         => $rabbit_hash[password],
        rabbit_user             => $rabbit_hash[user],
        qpid_password           => $rabbit_hash[password],
        qpid_user               => $rabbit_hash[user],
        export_resources        => false,
        quantum                 => $::use_quantum,
        quantum_user_password         => $quantum_hash[user_password],
        quantum_db_password           => $quantum_hash[db_password],
        quantum_network_node          => $::use_quantum,
        quantum_netnode_on_cnt        => true,
        quantum_gre_bind_addr         => $quantum_gre_bind_addr,
        quantum_external_ipinfo       => $external_ipinfo,
        tenant_network_type           => $tenant_network_type,
        segment_range                 => $segment_range,
        cinder                  => true,
        cinder_user_password    => $cinder_hash[user_password],
        cinder_db_password      => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $manage_volumes,
        use_syslog              => true,
        syslog_log_level        => $syslog_log_level,
        syslog_log_facility_glance   => $syslog_log_facility_glance,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_nova => $syslog_log_facility_nova,
        syslog_log_facility_keystone => $syslog_log_facility_keystone,
        cinder_rate_limits      => $cinder_rate_limits,
        horizon_use_ssl         => $horizon_use_ssl,
        nameservers             => $::dns_nameservers,
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }
      if $::quantum {
        class { '::openstack::quantum_router':
	        db_host               => $controller_node_address,
		      service_endpoint      => $controller_node_address,
		      auth_host             => $controller_node_address,
		      nova_api_vip          => $controller_node_address,
		      internal_address      => $internal_address,
		      public_interface      => $::public_int,
		      private_interface     => $::fuel_settings['fixed_interface'],
		      floating_range        => $floating_hash,
		      fixed_range           => $::fuel_settings['fixed_network_range'],
		      create_networks       => $create_networks,
		      debug                 => $debug ? { 'true' => true, true => true, default=> false },
		      verbose               => $verbose ? { 'true' => true, true => true, default=> false },
		      queue_provider        => $queue_provider,
		      rabbit_password       => $rabbit_hash[password],
		      rabbit_user           => $rabbit_hash[user],
		      rabbit_ha_virtual_ip  => $controller_node_address,
		      rabbit_nodes          => [$controller_node_address],
		      qpid_password         => $rabbit_hash[password],
		      qpid_user             => $rabbit_hash[user],
		      qpid_nodes            => [$controller_node_address],
		      quantum               => $::use_quantum,
		      quantum_user_password => $quantum_hash[user_password],
		      quantum_db_password   => $quantum_hash[db_password],
		      quantum_gre_bind_addr => $quantum_gre_bind_addr,
		      quantum_network_node  => true,
		      quantum_netnode_on_cnt=> $::use_quantum,
		      tenant_network_type   => $tenant_network_type,
		      segment_range         => $segment_range,
		      external_ipinfo       => $external_ipinfo,
		      api_bind_address      => $internal_address,
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


      # glance_image is currently broken in fuel

      # glance_image {'testvm':
      #   ensure           => present,
      #   name             => "Cirros testvm",
      #   is_public        => 'yes',
      #   container_format => 'ovf',
      #   disk_format      => 'raw',
      #   source           => '/opt/vm/cirros-0.3.0-x86_64-disk.img',
      #   require          => Class[glance::api],
      # }

      #TODO: fix this so it dosn't break ceph
      if !($::use_ceph) {
        class { 'openstack::img::cirros':
          os_username               => shellescape($access_hash[user]),
          os_password               => shellescape($access_hash[password]),
          os_tenant_name            => shellescape($access_hash[tenant]),
          img_name                  => "TestVM",
          stage                     => 'glance-image',
        }
        Class[glance::api]        -> Class[openstack::img::cirros]
      }

      if !$::use_quantum {
        nova_floating_range{ $floating_ips_range:
          ensure          => 'present',
          pool            => 'nova',
          username        => $access_hash[user],
          api_key         => $access_hash[password],
          auth_method     => 'password',
          auth_url        => "http://${controller_node_address}:5000/v2.0/",
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

    }

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $::public_int,
        private_interface      => $::fuel_settings['fixed_interface'],
        internal_address       => $internal_address,
        libvirt_type           => $::fuel_settings['libvirt_type'],
        fixed_range            => $::fuel_settings['fixed_network_range'],
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => $sql_connection,
        nova_user_password     => $nova_hash[user_password],
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
        quantum                => $::use_quantum,
        quantum_host           => $quantum_host,
        quantum_sql_connection => $quantum_sql_connection,
        quantum_user_password  => $quantum_hash[user_password],
        tenant_network_type    => $tenant_network_type,
        service_endpoint       => $controller_node_address,
        cinder                 => true,
        cinder_user_password   => $cinder_hash[user_password],
        cinder_db_password     => $cinder_hash[db_password],
        cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
        cinder_volume_group     => "cinder",
        manage_volumes          => $manage_volumes,
        db_host                => $controller_node_address,
        debug                  => $debug ? { 'true' => true, true => true, default=> false },
        verbose                => $verbose ? { 'true' => true, true => true, default=> false },
        use_syslog             => true,
        syslog_log_level       => $syslog_log_level,
        syslog_log_facility    => $syslog_log_facility_nova,
        syslog_log_facility_quantum => $syslog_log_facility_quantum,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
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
      $roles = node_roles($nodes_hash, $::fuel_settings['id'])
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
        rabbit_nodes         => [$controller_node_address],
        qpid_password        => $rabbit_hash[password],
        qpid_user            => $rabbit_hash[user],
        qpid_nodes           => [$controller_node_address],
        volume_group         => 'cinder',
        manage_volumes       => $manage_volumes,
        enabled              => true,
        bind_host            => $bind_host,
        auth_host            => $controller_node_address,
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $syslog_log_facility_cinder,
        syslog_log_level     => $syslog_log_level,
        debug                => $debug ? { 'true' => true, true => true, default=> false },
        verbose              => $verbose ? { 'true' => true, true => true, default=> false },
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
