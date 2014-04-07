class osnailyfacter::cluster_ha {

  ##PARAMETERS DERIVED FROM YAML FILE

  if $::use_quantum {
    $novanetwork_params  = {}
    $quantum_config = sanitize_neutron_config($::fuel_settings, 'quantum_settings')
  } else {
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

  if $::fuel_settings['role'] == 'primary-controller' {
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
  $mp_hash              = $::fuel_settings['mp']
  $network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"

  if !$rabbit_hash['user'] {
    $rabbit_hash['user'] = 'nova'
  }

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
      namespace            => 'haproxy',
      nic                  => $::public_int,
      base_veth            => "${::public_int}-hapr",
      ns_veth              => "hapr-p",
      ip                   => $::fuel_settings['public_vip'],
      cidr_netmask         => netmask_to_cidr($::fuel_settings['nodes'][0]['public_netmask']),
      gateway              => 'link',
      gateway_metric       => '10',
      iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${::public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -I POSTROUTING -m mark --mark 0x2a ! -o ${::public_int} -j MASQUERADE",
      iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${::public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -D POSTROUTING -m mark --mark 0x2a ! -o ${::public_int} -j MASQUERADE",
      iptables_comment     => "masquerade-for-public-net",
    },
    management_old   => {
      namespace            => 'haproxy',
      nic                  => $::internal_int,
      base_veth            => "${::internal_int}-hapr",
      ns_veth              => "hapr-m",
      ip                   => $::fuel_settings['management_vip'],
      cidr_netmask         => netmask_to_cidr($::fuel_settings['nodes'][0]['internal_netmask']),
      gateway              => 'link',
      gateway_metric       => '20',
      iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${::internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -I POSTROUTING -m mark --mark 0x2b ! -o ${::internal_int} -j MASQUERADE",
      iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${::internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -D POSTROUTING -m mark --mark 0x2b ! -o ${::internal_int} -j MASQUERADE",
      iptables_comment     => "masquerade-for-management-net",
    },
  }

  $vip_keys = keys($vips)

  ##REFACTORING NEEDED


  ##TODO: simply parse nodes array
  $controllers = merge_arrays(filter_nodes($nodes_hash,'role','primary-controller'), filter_nodes($nodes_hash,'role','controller'))
  $controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
  $controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
  $controller_storage_addresses = nodes_to_hash($controllers,'name','storage_address')
  $controller_hostnames = keys($controller_internal_addresses)
  $controller_nodes = ipsort(values($controller_internal_addresses))
  $controller_node_public  = $::fuel_settings['public_vip']
  $controller_node_address = $::fuel_settings['management_vip']
  $roles = node_roles($nodes_hash, $::fuel_settings['uid'])
  $mountpoints = filter_hash($mp_hash,'point')

  # AMQP client configuration
  if $::internal_address in $controller_nodes {
    # prefer local MQ broker if it exists on this node
    $amqp_nodes = concat(['127.0.0.1'], $controller_nodes)
  } else {
    $amqp_nodes = $controller_nodes
  }
  $amqp_port = '5673'
  $amqp_hosts = inline_template("<%= @amqp_nodes.map {|x| x + ':' + @amqp_port}.join ',' %>")
  $rabbit_ha_queues = true

  # RabbitMQ server configuration
  $rabbitmq_bind_ip_address = 'UNSET'              # bind RabbitMQ to 0.0.0.0
  $rabbitmq_bind_port = $amqp_port
  $rabbitmq_cluster_nodes = $controller_hostnames  # has to be hostnames

  # SQLAlchemy backend configuration
  $max_pool_size = min($::processorcount * 5 + 0, 30 + 0)
  $max_overflow = min($::processorcount * 5 + 0, 60 + 0)
  $max_retries = '-1'
  $idle_timeout = '3600'

  $cinder_iscsi_bind_addr = $::storage_address

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
    $glance_backend = 'swift'
  }

  if ($::use_ceph) {
    $primary_mons   = $controllers
    $primary_mon    = $controllers[0]['name']

    class {'ceph':
      primary_mon          => $primary_mon,
      cluster_node_address => $controller_node_public,
      use_rgw              => $storage_hash['objects_ceph'],
      glance_backend       => $glance_backend,
      rgw_pub_ip           => $::fuel_settings['public_vip'],
      rgw_adm_ip           => $::fuel_settings['management_vip'],
      rgw_int_ip           => $::fuel_settings['management_vip'],
    }
  }

  # Use Swift if it isn't replaced by Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) {
    $use_swift = true
  } else {
    $use_swift = false
  }

  if ($use_swift) {
    if !$::fuel_settings['swift_partition'] {
      $swift_partition = '/var/lib/glance/node'
    }
    $swift_proxies            = $controllers
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
  } elsif ($storage_hash['objects_ceph']) {
    $rgw_servers = $controllers
  }


  $network_config = {
    'vlan_start'     => $vlan_start,
  }

  # from site.pp top scope
  $use_syslog = $::use_syslog
  $verbose = $::verbose
  $debug = $::debug

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
      controllers                   => $::osnailyfacter::cluster_ha::controllers,
      controller_public_addresses   => $::osnailyfacter::cluster_ha::controller_public_addresses,
      controller_internal_addresses => $::osnailyfacter::cluster_ha::controller_internal_addresses,
      internal_address              => $::internal_address,
      public_interface              => $::public_int,
      private_interface             => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_interface']},
      internal_virtual_ip           => $::fuel_settings['management_vip'],
      public_virtual_ip             => $::fuel_settings['public_vip'],
      primary_controller            => $::osnailyfacter::cluster_ha::primary_controller,
      floating_range                => $::use_quantum ? { true=>$floating_hash, default=>false},
      fixed_range                   => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_network_range']},
      multi_host                    => $::osnailyfacter::cluster_ha::multi_host,
      network_manager               => $::osnailyfacter::cluster_ha::network_manager,
      num_networks                  => $::osnailyfacter::cluster_ha::num_networks,
      network_size                  => $::osnailyfacter::cluster_ha::network_size,
      network_config                => $::osnailyfacter::cluster_ha::network_config,
      debug                         => $::osnailyfacter::cluster_ha::debug,
      verbose                       => $::osnailyfacter::cluster_ha::verbose,
      auto_assign_floating_ip       => $::fuel_settings['auto_assign_floating_ip'],
      mysql_root_password           => $::osnailyfacter::cluster_ha::mysql_hash[root_password],
      admin_email                   => $::osnailyfacter::cluster_ha::access_hash[email],
      admin_user                    => $::osnailyfacter::cluster_ha::access_hash[user],
      admin_password                => $::osnailyfacter::cluster_ha::access_hash[password],
      keystone_db_password          => $::osnailyfacter::cluster_ha::keystone_hash[db_password],
      keystone_admin_token          => $::osnailyfacter::cluster_ha::keystone_hash[admin_token],
      keystone_admin_tenant         => $::osnailyfacter::cluster_ha::access_hash[tenant],
      glance_db_password            => $::osnailyfacter::cluster_ha::glance_hash[db_password],
      glance_user_password          => $::osnailyfacter::cluster_ha::glance_hash[user_password],
      glance_image_cache_max_size   => $::osnailyfacter::cluster_ha::glance_hash[image_cache_max_size],
      nova_db_password              => $::osnailyfacter::cluster_ha::nova_hash[db_password],
      nova_user_password            => $::osnailyfacter::cluster_ha::nova_hash[user_password],
      queue_provider                => $::queue_provider,
      amqp_hosts                    => $::osnailyfacter::cluster_ha::amqp_hosts,
      amqp_user                     => $::osnailyfacter::cluster_ha::rabbit_hash['user'],
      amqp_password                 => $::osnailyfacter::cluster_ha::rabbit_hash['password'],
      rabbit_ha_queues              => $::osnailyfacter::cluster_ha::rabbit_ha_queues,
      rabbitmq_bind_ip_address      => $::osnailyfacter::cluster_ha::rabbitmq_bind_ip_address,
      rabbitmq_bind_port            => $::osnailyfacter::cluster_ha::rabbitmq_bind_port,
      rabbitmq_cluster_nodes        => $::osnailyfacter::cluster_ha::rabbitmq_cluster_nodes,
      memcached_servers             => $::osnailyfacter::cluster_ha::controller_nodes,
      export_resources              => false,
      glance_backend                => $::osnailyfacter::cluster_ha::glance_backend,
      swift_proxies                 => $::osnailyfacter::cluster_ha::swift_proxies,
      rgw_servers                   => $::osnailyfacter::cluster_ha::rgw_servers,
      quantum                       => $::use_quantum,
      quantum_config                => $::osnailyfacter::cluster_ha::quantum_config,
      quantum_network_node          => $::use_quantum,
      quantum_netnode_on_cnt        => $::use_quantum,
      cinder                        => true,
      cinder_user_password          => $::osnailyfacter::cluster_ha::cinder_hash[user_password],
      cinder_iscsi_bind_addr        => $::osnailyfacter::cluster_ha::cinder_iscsi_bind_addr,
      cinder_db_password            => $::osnailyfacter::cluster_ha::cinder_hash[db_password],
      cinder_volume_group           => "cinder",
      manage_volumes                => $::osnailyfacter::cluster_ha::manage_volumes,
      ceilometer                    => $::osnailyfacter::cluster_ha::ceilometer_hash[enabled],
      ceilometer_db_password        => $::osnailyfacter::cluster_ha::ceilometer_hash[db_password],
      ceilometer_user_password      => $::osnailyfacter::cluster_ha::ceilometer_hash[user_password],
      ceilometer_metering_secret    => $::osnailyfacter::cluster_ha::ceilometer_hash[metering_secret],
      ceilometer_db_type            => 'mongodb',
      ceilometer_db_host            => mongo_hosts($nodes_hash),
      galera_nodes                  => $::osnailyfacter::cluster_ha::controller_nodes,
      novnc_address                 => $::internal_address,
      sahara                        => $::osnailyfacter::cluster_ha::sahara_hash[enabled],
      murano                        => $::osnailyfacter::cluster_ha::murano_hash['enabled'],
      custom_mysql_setup_class      => $::custom_mysql_setup_class,
      mysql_skip_name_resolve       => true,
      use_syslog                    => $::osnailyfacter::cluster_ha::use_syslog,
      syslog_log_level              => $::syslog_log_level,
      syslog_log_facility_glance    => $::syslog_log_facility_glance,
      syslog_log_facility_cinder    => $::syslog_log_facility_cinder,
      syslog_log_facility_neutron   => $::syslog_log_facility_neutron,
      syslog_log_facility_nova      => $::syslog_log_facility_nova,
      syslog_log_facility_keystone  => $::syslog_log_facility_keystone,
      nova_rate_limits              => $::nova_rate_limits,
      cinder_rate_limits            => $::cinder_rate_limits,
      horizon_use_ssl               => $::fuel_settings['horizon_use_ssl'],
      use_unicast_corosync          => $::fuel_settings['use_unicast_corosync'],
      nameservers                   => $::dns_nameservers,
      max_retries                   => $max_retries,
      max_pool_size                 => $max_pool_size,
      max_overflow                  => $max_overflow,
      idle_timeout                  => $idle_timeout,
      nova_report_interval          => $::nova_report_interval,
      nova_service_down_time        => $::nova_service_down_time,
    }
  }


  class virtual_ips () {
    cluster::virtual_ips { $::osnailyfacter::cluster_ha::vip_keys:
      vips => $::osnailyfacter::cluster_ha::vips,
    }
  }



  case $::fuel_settings['role'] {
    /controller/ : {
      include osnailyfacter::test_controller

      class { '::cluster':
        stage             => 'corosync_setup',
        internal_address  => $::internal_address,
        unicast_addresses => $::osnailyfacter::cluster_ha::controller_internal_addresses,
      }

      if $::fuel_settings['role'] == 'primary-controller' {
        Class['::cluster']->
        class { 'virtual_ips': stage => 'corosync_setup' }
      }

      class { 'cluster::haproxy': haproxy_maxconn => '16000' }

      class { 'compact_controller': }
      if ($use_swift) {
        $swift_zone = $node[0]['swift_zone']

        class { 'openstack::swift::storage_node':
          storage_type          => $swift_loopback,
          loopback_size         => '5243780',
          storage_mnt_base_dir  => $swift_partition,
          storage_devices       => $mountpoints,
          swift_zone            => $swift_zone,
          swift_local_net_ip    => $::storage_address,
          master_swift_proxy_ip => $master_swift_proxy_ip,
          sync_rings            => ! $primary_proxy,
          syslog_log_level      => $::syslog_log_level,
          debug                 => $::debug,
          verbose               => $::verbose,
        }
        if $primary_proxy {
          ring_devices {'all': storages => $controllers }
        }

        if !$swift_hash['resize_value']
        {
          $swift_hash['resize_value'] = 2
        }

        $ring_part_power=calc_ring_part_power($controllers,$swift_hash['resize_value'])

        class { 'openstack::swift::proxy':
          swift_user_password     => $swift_hash[user_password],
          swift_proxies           => $controller_internal_addresses,
          ring_part_power         => $ring_part_power,
          primary_proxy           => $primary_proxy,
          controller_node_address => $::fuel_settings['management_vip'],
          swift_local_net_ip      => $swift_local_net_ip,
          master_swift_proxy_ip   => $master_swift_proxy_ip,
          syslog_log_level        => $::syslog_log_level,
          debug                   => $::debug,
          verbose                 => $::verbose,
        }
        class { 'swift::keystone::auth':
          password         => $swift_hash[user_password],
          public_address   => $::fuel_settings['public_vip'],
          internal_address => $::fuel_settings['management_vip'],
          admin_address    => $::fuel_settings['management_vip'],
        }
      }
      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images':            value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver':  value => $::fuel_settings['compute_scheduler_driver'] }

      if ! $::use_quantum {
        nova_floating_range { $floating_ips_range:
          ensure          => 'present',
          pool            => 'nova',
          username        => $access_hash[user],
          api_key         => $access_hash[password],
          auth_method     => 'password',
          auth_url        => "http://${::fuel_settings['management_vip']}:5000/v2.0/",
          authtenant_name => $access_hash[tenant],
          api_retries     => 10,
        }
        Class['nova::api', 'openstack::ha::nova'] -> Nova_floating_range <| |>
      }
      if ($::use_ceph){
        Class['openstack::controller'] -> Class['ceph']
      }

      #ADDONS START

      if $sahara_hash['enabled'] {
        class { 'sahara' :
          sahara_api_host            => $::fuel_settings['public_vip'],

          sahara_db_password         => $sahara_hash['db_password'],
          sahara_db_host             => $::fuel_settings['management_vip'],

          sahara_keystone_host       => $::fuel_settings['management_vip'],
          sahara_keystone_user       => 'sahara',
          sahara_keystone_password   => $sahara_hash['user_password'],
          sahara_keystone_tenant     => 'services',

          use_neutron                => $::use_quantum,
          use_floating_ips           => $::fuel_settings['auto_assign_floating_ip'],

          syslog_log_facility_sahara => $syslog_log_facility_sahara,
          syslog_log_level           => $syslog_log_level,
          debug                      => $::debug,
          verbose                    => $::verbose,
          use_syslog                 => $::use_syslog,
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

        #FIXME: Disable heat for Red Hat OpenStack 3.0
        if ($::operatingsystem != 'RedHat') {
          class { 'heat' :
            pacemaker              => true,
            external_ip            => $controller_node_public,

            keystone_host     => $controller_node_address,
            keystone_user     => 'heat',
            keystone_password => 'heat',
            keystone_tenant   => 'services',

            amqp_hosts       => $amqp_hosts,
            amqp_user        => $rabbit_hash['user'],
            amqp_password    => $rabbit_hash['password'],
            rabbit_ha_queues => $rabbit_ha_queues,

            db_host           => $controller_node_address,
            db_password       => $heat_hash['db_password'],

            debug               => $::debug,
            verbose             => $::verbose,
            use_syslog          => $::use_syslog,
            syslog_log_facility => $::syslog_log_facility_heat,
          }
      }

      if $murano_hash['enabled'] {

        class { 'murano' :
          murano_api_host          => $::fuel_settings['public_vip'],

          # Murano uses two RabbitMQ - one from OpenStack and another one installed on each controller.
          #   The second instance is used for communication with agents.
          #   * murano_rabbit_host provides address for murano-engine which communicates with this
          #    'separate' rabbitmq directly (without oslo.messaging).
          #   * murano_rabbit_ha_hosts / murano_rabbit_ha_queues are required for murano-api which
          #     communicates with 'system' RabbitMQ and uses oslo.messaging.
          murano_rabbit_host       => $::fuel_settings['public_vip'],
          murano_rabbit_ha_hosts   => $amqp_hosts,
          murano_rabbit_ha_queues  => $rabbit_ha_queues,
          murano_rabbit_login      => 'murano',
          murano_rabbit_password   => $heat_hash['rabbit_password'],

          murano_db_host           => $::fuel_settings['management_vip'],
          murano_db_password       => $murano_hash['db_password'],

          murano_keystone_host     => $::fuel_settings['management_vip'],
          murano_keystone_user     => 'murano',
          murano_keystone_password => $murano_hash['user_password'],
          murano_keystone_tenant   => 'services',

          use_neutron              => $::use_quantum,

          use_syslog               => $::use_syslog,
          debug                    => $::debug,
          verbose                  => $::verbose,
          syslog_log_facility      => $::syslog_log_facility_murano,

          primary_controller       => $primary_controller,
        }

       Class['heat'] -> Class['murano']

      }

      # vCenter integration

      if $::fuel_settings['role'] == 'primary-controller' {
        if $::fuel_settings['libvirt_type'] == 'vcenter' {
          class { 'vmware' :
            vcenter_user      => $vcenter_hash['vc_user'],
            vcenter_password  => $vcenter_hash['vc_password'],
            vcenter_host_ip   => $vcenter_hash['host_ip'],
            vcenter_cluster   => $vcenter_hash['cluster'],
            use_quantum       => $::use_quantum,
          }
        }
      }

      #ADDONS END

    } #CONTROLLER ENDS

    "compute" : {
      include osnailyfacter::test_compute

      class { 'openstack::compute':
        public_interface       => $::public_int,
        private_interface      => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_interface'] },
        internal_address       => $::internal_address,
        libvirt_type           => $::fuel_settings['libvirt_type'],
        fixed_range            => $::use_quantum ? { true=>false, default=>$::fuel_settings['fixed_network_range']},
        network_manager        => $network_manager,
        network_config         => $network_config,
        multi_host             => $multi_host,
        sql_connection         => "mysql://nova:${nova_hash[db_password]}@${::fuel_settings['management_vip']}/nova?read_timeout=60",
        queue_provider         => $::queue_provider,
        amqp_hosts             => $amqp_hosts,
        amqp_user              => $rabbit_hash['user'],
        amqp_password          => $rabbit_hash['password'],
        rabbit_ha_queues       => $rabbit_ha_queues,
        auto_assign_floating_ip => $::fuel_settings['auto_assign_floating_ip'],
        glance_api_servers     => "${::fuel_settings['management_vip']}:9292",
        vncproxy_host          => $::fuel_settings['public_vip'],
        vncserver_listen       => '0.0.0.0',
        debug                  => $::debug,
        verbose                => $::verbose,
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
        ceilometer             => $ceilometer_hash[enabled],
        ceilometer_metering_secret => $ceilometer_hash[metering_secret],
        ceilometer_user_password => $ceilometer_hash[user_password],
        db_host                => $::fuel_settings['management_vip'],
        quantum                => $::use_quantum,
        quantum_config         => $quantum_config,
        use_syslog             => $use_syslog,
        syslog_log_level       => $::syslog_log_level,
        syslog_log_facility    => $::syslog_log_facility_nova,
        syslog_log_facility_neutron => $::syslog_log_facility_neutron,
        syslog_log_facility_cinder => $::syslog_log_facility_cinder,
        nova_rate_limits       => $::nova_rate_limits,
        nova_report_interval   => $::nova_report_interval,
        nova_service_down_time => $::nova_service_down_time,
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

    "cinder" : {
      include keystone::python
      #FIXME(bogdando) notify services on python-amqp update, if needed
      package { 'python-amqp':
        ensure => present
      }
      if member($roles, 'controller') or member($roles, 'primary-controller') {
        $bind_host = $::internal_address
      } else {
        $bind_host = false
      }
      class { 'openstack::cinder':
        sql_connection       => "mysql://cinder:${cinder_hash[db_password]}@${::fuel_settings['management_vip']}/cinder?charset=utf8&read_timeout=60",
        glance_api_servers   => "${::fuel_settings['management_vip']}:9292",
        bind_host            => $bind_host,
        queue_provider       => $::queue_provider,
        amqp_hosts           => $amqp_hosts,
        amqp_user            => $rabbit_hash['user'],
        amqp_password        => $rabbit_hash['password'],
        rabbit_ha_queues     => $rabbit_ha_queues,
        volume_group         => 'cinder',
        manage_volumes       => $manage_volumes,
        enabled              => true,
        auth_host            => $::fuel_settings['management_vip'],
        iscsi_bind_host      => $::storage_address,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $::syslog_log_facility_cinder,
        syslog_log_level     => $::syslog_log_level,
        debug                => $::debug,
        verbose              => $::verbose,
        use_syslog           => $::use_syslog,
        max_retries          => $max_retries,
        max_pool_size        => $max_pool_size,
        max_overflow         => $max_overflow,
        idle_timeout         => $idle_timeout,

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

  class { 'zabbix': }

} # CLUSTER_HA ENDS
# vim: set ts=2 sw=2 et :
