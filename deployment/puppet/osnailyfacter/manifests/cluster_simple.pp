class osnailyfacter::cluster_simple {

  if $::use_monit {
    # Configure service names for monit watchdogs and 'service' system path
    # FIXME(bogdando) replace service_path to systemd, once supported
    include nova::params
    include cinder::params
    include neutron::params
    include l23network::params
    $nova_compute_name   = $::nova::params::compute_service_name
    $nova_api_name       = $::nova::params::api_service_name
    $nova_network_name   = $::nova::params::network_service_name
    $cinder_volume_name  = $::cinder::params::volume_service
    $ovs_vswitchd_name   = $::l23network::params::ovs_service_name
    case $::osfamily {
      'RedHat' : {
         $service_path   = '/sbin/service'
      }
      'Debian' : {
        $service_path    = '/usr/sbin/service'
      }
      default  : {
        fail("Unsupported osfamily: ${osfamily} for os ${operatingsystem}")
      }
    }
  }

  if $::use_neutron {
    $novanetwork_params        = {}
    $neutron_config            = $::fuel_settings['quantum_settings']
    $network_provider          = 'neutron'
    $neutron_db_password       = $neutron_config['database']['passwd']
    $neutron_user_password     = $neutron_config['keystone']['admin_password']
    $neutron_metadata_proxy_secret = $neutron_config['metadata']['metadata_proxy_shared_secret']
    $base_mac                  = $neutron_config['L2']['base_mac']
    if $::fuel_settings['nsx_plugin']['metadata']['enabled'] {
      $use_vmware_nsx     = true
      $neutron_nsx_config = $::fuel_settings['nsx_plugin']
    }
  } else {
    $neutron_config     = {}
    $novanetwork_params = $::fuel_settings['novanetwork_parameters']
    $network_size       = $novanetwork_params['network_size']
    $num_networks       = $novanetwork_params['num_networks']
    $vlan_start         = $novanetwork_params['vlan_start']
    $network_provider   = 'nova'
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
  } else {
    $vcenter_hash = {}
  }

  if $::fuel_settings['role'] == 'controller' {
    if ($::mellanox_mode == 'ethernet') {
      $test_vm_pkg = 'cirros-testvm-mellanox'
    } else {
      $test_vm_pkg = 'cirros-testvm'
    }
    package { 'cirros-testvm' :
      ensure => 'installed',
      name   => $test_vm_pkg,
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
  } elsif (member($roles, 'cinder') and $storage_hash['volumes_vmdk']) {
    $manage_volumes = 'vmdk'
  } elsif ($storage_hash['volumes_ceph']) {
    $manage_volumes = 'ceph'
  } else {
    $manage_volumes = false
  }

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
      swift_endpoint_port    => '6780',
      use_syslog             => $::use_syslog,
      syslog_log_level       => $syslog_log_level,
      syslog_log_facility    => $::syslog_log_facility_ceph,
    }
  }

  if ($::mellanox_mode != 'disabled') {
    class { 'mellanox_openstack::openibd' : }
  }



  case $::fuel_settings['role'] {
    "controller" : {
      include osnailyfacter::test_controller

      class {'osnailyfacter::apache_api_proxy':}
      class { 'openstack::controller':
        admin_address                  => $controller_node_address,
        public_address                 => $controller_node_public,
        public_interface               => $::public_int,
        private_interface              => $::use_neutron ? { true=>false, default=>$::fuel_settings['fixed_interface']},
        internal_address               => $controller_node_address,
        service_endpoint               => $controller_node_address,
        floating_range                 => false, #todo: remove as not needed ???
        fixed_range                    => $::use_neutron ? { true=>false, default=>$::fuel_settings['fixed_network_range'] },
        multi_host                     => $multi_host,
        network_manager                => $network_manager,
        num_networks                   => $::use_neutron ? { true=>false, default=>$novanetwork_params['num_networks'] },
        network_size                   => $::use_neutron ? { true=>false, default=>$novanetwork_params['network_size'] },
        network_config                 => $::use_neutron ? { true=>false, default=>$network_config },
        debug                          => $debug,
        verbose                        => $verbose,
        auto_assign_floating_ip        => $::fuel_settings['auto_assign_floating_ip'],
        mysql_root_password            => $mysql_hash[root_password],
        admin_email                    => $access_hash[email],
        admin_user                     => $access_hash[user],
        admin_password                 => $access_hash[password],
        keystone_db_password           => $keystone_hash[db_password],
        keystone_admin_token           => $keystone_hash[admin_token],
        keystone_admin_tenant          => $access_hash[tenant],
        glance_db_password             => $glance_hash[db_password],
        glance_user_password           => $glance_hash[user_password],
        glance_backend                 => $glance_backend,
        glance_image_cache_max_size    => $glance_hash[image_cache_max_size],
        known_stores                   => $glance_known_stores,
        glance_vcenter_host            => $storage_hash['vc_host'],
        glance_vcenter_user            => $storage_hash['vc_user'],
        glance_vcenter_password        => $storage_hash['vc_password'],
        glance_vcenter_datacenter      => $storage_hash['vc_datacenter'],
        glance_vcenter_datastore       => $storage_hash['vc_datastore'],
        glance_vcenter_image_dir       => $storage_hash['vc_image_dir'],
        nova_db_password               => $nova_hash[db_password],
        nova_user_password             => $nova_hash[user_password],
        nova_rate_limits               => $::nova_rate_limits,
        ceilometer                     => $ceilometer_hash[enabled],
        ceilometer_db_password         => $ceilometer_hash[db_password],
        ceilometer_user_password       => $ceilometer_hash[user_password],
        ceilometer_metering_secret     => $ceilometer_hash[metering_secret],
        ceilometer_db_type             => 'mongodb',
        ceilometer_db_host             => mongo_hosts($nodes_hash),
        swift_rados_backend            => $storage_hash['objects_ceph'],
        queue_provider                 => $::queue_provider,
        amqp_hosts                     => $amqp_hosts,
        amqp_user                      => $rabbit_hash['user'],
        amqp_password                  => $rabbit_hash['password'],
        rabbitmq_bind_ip_address       => $rabbitmq_bind_ip_address,
        rabbitmq_bind_port             => $rabbitmq_bind_port,
        rabbitmq_cluster_nodes         => $rabbitmq_cluster_nodes,
        export_resources               => false,

        network_provider               => $network_provider,
        neutron_db_password            => $neutron_db_password,
        neutron_user_password          => $neutron_user_password,
        neutron_metadata_proxy_secret  => $neutron_metadata_proxy_secret,
        base_mac                       => $base_mac,

        cinder                         => true,
        cinder_user_password           => $cinder_hash[user_password],
        cinder_db_password             => $cinder_hash[db_password],
        cinder_iscsi_bind_addr         => $cinder_iscsi_bind_addr,
        cinder_volume_group            => "cinder",
        manage_volumes                 => $manage_volumes,
        use_syslog                     => $use_syslog,
        novnc_address                  => $controller_node_public,
        syslog_log_facility_glance     => $::syslog_log_facility_glance,
        syslog_log_facility_cinder     => $::syslog_log_facility_cinder,
        syslog_log_facility_neutron    => $::syslog_log_facility_neutron,
        syslog_log_facility_nova       => $::syslog_log_facility_nova,
        syslog_log_facility_keystone   => $::syslog_log_facility_keystone,
        syslog_log_facility_ceilometer => $::syslog_log_facility_ceilometer,
        cinder_rate_limits             => $::cinder_rate_limits,
        horizon_use_ssl                => $::horizon_use_ssl,
        nameservers                    => $::dns_nameservers,
        primary_controller             => true,
        max_retries                    => $max_retries,
        max_pool_size                  => $max_pool_size,
        max_overflow                   => $max_overflow,
        idle_timeout                   => $idle_timeout,
        nova_report_interval           => $::nova_report_interval,
        nova_service_down_time         => $::nova_service_down_time,
        cache_server_ip                => [$internal_address],
        memcached_bind_address         => $internal_address,
      }

      nova_config { 'DEFAULT/resume_guests_state_on_host_boot': value => $::fuel_settings['resume_guests_state_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

      if $use_vmware_nsx {
        class {'plugin_neutronnsx':
          neutron_config     => $neutron_config,
          neutron_nsx_config => $neutron_nsx_config,
        }
      }

      if !$::use_neutron {
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
        Class[nova::api, nova::keystone::auth] -> Nova_floating_range <| |>
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
          sahara_auth_uri            => "http://${controller_node_address}:5000/v2.0/",
          sahara_identity_uri        => "http://${controller_node_address}:35357/",
          use_neutron                => $::use_neutron,
          syslog_log_facility_sahara => $syslog_log_facility_sahara,
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
        scheduler_default_filters  => concat($scheduler_default_filters, [ 'RetryFilter', 'AvailabilityZoneFilter', 'RamFilter', 'CoreFilter', 'DiskFilter', 'ComputeFilter', 'ComputeCapabilitiesFilter', 'ImagePropertiesFilter' ])
      }

      # From logasy filter.pp
      nova_config {
        'DEFAULT/ram_weight_multiplier':        value => '1.0'
      }


      class { 'openstack::heat' :
        pacemaker           => false,
        external_ip         => $controller_node_public,

        keystone_host       => $controller_node_address,
        keystone_user       => 'heat',
        keystone_password   => $heat_hash['user_password'],
        keystone_tenant     => 'services',

        keystone_ec2_uri    => "http://${controller_node_address}:5000/v2.0",

        rpc_backend         => 'heat.openstack.common.rpc.impl_kombu',
        amqp_hosts          => [$amqp_hosts],
        amqp_user           => $rabbit_hash['user'],
        amqp_password       => $rabbit_hash['password'],

        sql_connection      =>
          "mysql://heat:${heat_hash['db_password']}@${$controller_node_address}/heat?read_timeout=60",
        db_host             => $controller_node_address,
        db_password         => $heat_hash['db_password'],
        max_retries         => $max_retries,
        max_pool_size       => $max_pool_size,
        max_overflow        => $max_overflow,
        idle_timeout        => $idle_timeout,

        debug               => $::debug,
        verbose             => $::verbose,
        use_syslog          => $::use_syslog,
        syslog_log_facility => $::syslog_log_facility_heat,
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

          murano_os_rabbit_userid  => $rabbit_hash['user'],
          murano_os_rabbit_passwd  => $rabbit_hash['password'],
          murano_own_rabbit_userid => 'murano',
          murano_own_rabbit_passwd => $heat_hash['rabbit_password'],

          murano_db_host           => $controller_node_address,
          murano_db_password       => $murano_hash['db_password'],

          murano_keystone_host     => $controller_node_address,
          murano_keystone_user     => 'murano',
          murano_keystone_password => $murano_hash['user_password'],
          murano_keystone_tenant   => 'services',

          use_neutron              => $::use_neutron,

          use_syslog               => $use_syslog,
          debug                    => $debug,
          verbose                  => $verbose,
          syslog_log_facility      => $syslog_log_facility_murano,
        }

        Class['openstack::heat'] -> Class['murano']

      }

      # vCenter integration
      if $::fuel_settings['libvirt_type'] == 'vcenter' {
        class { 'vmware' :
          vcenter_user      => $vcenter_hash['vc_user'],
          vcenter_password  => $vcenter_hash['vc_password'],
          vcenter_host_ip   => $vcenter_hash['host_ip'],
          vcenter_cluster   => $vcenter_hash['cluster'],
          vnc_address       => $controller_node_public,
          use_quantum       => $::use_neutron,
        }
      }

      if ($::mellanox_mode == 'ethernet') {
        $ml2_eswitch = $::fuel_settings['neutron_mellanox']['ml2_eswitch']
        class { 'mellanox_openstack::controller':
          eswitch_vnic_type            => $ml2_eswitch['vnic_type'],
          eswitch_apply_profile_patch  => $ml2_eswitch['apply_profile_patch'],
        }
      }
      #ADDONS END

    }

    "compute" : {
      include osnailyfacter::test_compute

      if ($::mellanox_mode == 'ethernet') {
        $net04_physnet = $neutron_config['predefined_networks']['net04']['L2']['physnet']
        class { 'mellanox_openstack::compute':
          physnet => $net04_physnet,
          physifc => $::fuel_settings['neutron_mellanox']['physical_port'],
        }
        $libvirt_vif_driver             = 'mlnxvif.vif.MlxEthVIFDriver'
      } else {
        $libvirt_vif_driver             = 'nova.virt.libvirt.vif.LibvirtGenericVIFDriver'
      }

      class { 'openstack::compute':
        public_interface               => $::public_int ? { undef=>'', default=>$::public_int },
        private_interface              => $::use_neutron ? { true=>false, default=>$::fuel_settings['fixed_interface'] },
        internal_address               => $::internal_address,
        libvirt_type                   => $::fuel_settings['libvirt_type'],
        fixed_range                    => $::fuel_settings['fixed_network_range'],
        network_manager                => $network_manager,
        network_config                 => $::use_neutron ? { true=>false, default=>$network_config },
        multi_host                     => $multi_host,
        sql_connection                 => $sql_connection,
        nova_user_password             => $nova_hash[user_password],
        ceilometer                     => $ceilometer_hash[enabled],
        ceilometer_metering_secret     => $ceilometer_hash[metering_secret],
        ceilometer_user_password       => $ceilometer_hash[user_password],
        queue_provider                 => $::queue_provider,
        amqp_hosts                     => $amqp_hosts,
        amqp_user                      => $rabbit_hash['user'],
        amqp_password                  => $rabbit_hash['password'],
        auto_assign_floating_ip        => $::fuel_settings['auto_assign_floating_ip'],
        glance_api_servers             => "${controller_node_address}:9292",
        vncproxy_host                  => $controller_node_public,
        vncserver_listen               => '0.0.0.0',
        vnc_enabled                    => true,
        network_provider               => $network_provider,
        neutron_user_password          => $neutron_user_password,
        base_mac                       => $base_mac,
        service_endpoint               => $controller_node_address,
        cinder                         => true,
        cinder_user_password           => $cinder_hash[user_password],
        cinder_db_password             => $cinder_hash[db_password],
        cinder_iscsi_bind_addr         => $cinder_iscsi_bind_addr,
        cinder_volume_group            => "cinder",
        manage_volumes                 => $manage_volumes,
        db_host                        => $controller_node_address,
        debug                          => $debug,
        verbose                        => $verbose,
        use_syslog                     => $use_syslog,
        syslog_log_facility            => $::syslog_log_facility_nova,
        syslog_log_facility_neutron    => $::syslog_log_facility_neutron,
        syslog_log_facility_ceilometer => $::syslog_log_facility_ceilometer,
        state_path                     => $nova_hash[state_path],
        nova_rate_limits               => $::nova_rate_limits,
        nova_report_interval           => $::nova_report_interval,
        nova_service_down_time         => $::nova_service_down_time,
        cinder_rate_limits             => $::cinder_rate_limits,
        libvirt_vif_driver             => $libvirt_vif_driver,
      }
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

      if ($::use_ceph){
        Class['openstack::compute'] -> Class['ceph']
      }

      if $use_vmware_nsx {
        class {'plugin_neutronnsx':
          neutron_config     => $neutron_config,
          neutron_nsx_config => $neutron_nsx_config,
        }
      }

    # Configure monit watchdogs
    # FIXME(bogdando) replace service_path and action to systemd, once supported
    if $::use_monit {
      monit::process { $nova_compute_name :
        ensure        => running,
        matching      => '/usr/bin/python /usr/bin/nova-compute',
        start_command => "${service_path} ${nova_compute_name} restart",
        stop_command  => "${service_path} ${nova_compute_name} stop",
        pidfile       => false,
      }
      if $::use_quantum {
        monit::process { $ovs_vswitchd_name :
          ensure        => running,
          start_command => "${service_path} ${ovs_vswitchd_name} restart",
          stop_command  => "${service_path} ${ovs_vswitchd_name} stop",
          pidfile       => '/var/run/openvswitch/ovs-vswitchd.pid',
        }
      } else {
        monit::process { $nova_network_name :
          ensure        => running,
          matching      => '/usr/bin/python /usr/bin/nova-network',
          start_command => "${service_path} ${nova_network_name} restart",
          stop_command  => "${service_path} ${nova_network_name} stop",
          pidfile       => false,
        }
        monit::process { $nova_api_name :
          ensure        => running,
          matching      => '/usr/bin/python /usr/bin/nova-api',
          start_command => "${service_path} ${nova_api_name} restart",
          stop_command  => "${service_path} ${nova_api_name} stop",
          pidfile       => false,
        }
      }
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
        iser                 => $storage_hash['iser'],
        enabled              => true,
        auth_host            => $controller_node_address,
        iscsi_bind_host      => $cinder_iscsi_bind_addr,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $::syslog_log_facility_cinder,
        debug                => $debug,
        verbose              => $verbose,
        use_syslog           => $use_syslog,
        max_retries          => $max_retries,
        max_pool_size        => $max_pool_size,
        max_overflow         => $max_overflow,
        idle_timeout         => $idle_timeout,
        ceilometer           => $ceilometer_hash[enabled],
        vmware_host_ip       => $vcenter_hash['host_ip'],
        vmware_host_username => $vcenter_hash['vc_user'],
        vmware_host_password => $vcenter_hash['vc_password']
      }

      # FIXME(bogdando) replace service_path and action to systemd, once supported
      if $::use_monit {
        monit::process { $cinder_volume_name :
          ensure        => running,
          matching      => '/usr/bin/python /usr/bin/cinder-volume',
          start_command => "${service_path} ${cinder_volume_name} restart",
          stop_command  => "${service_path} ${cinder_volume_name} stop",
          pidfile       => false,
        }
      }

    } #CINDER ENDS

    "ceph-osd" : {
      #Nothing needs to be done Class Ceph is already defined
      notify {"ceph-osd: ${::ceph::osd_devices}": }
      notify {"osd_devices:  ${::osd_devices_list}": }
      # TODO(bogdando) add monit ceph-osd services monitoring, if required
    } #CEPH_OSD ENDS

  } # ROLE CASE ENDS

  # TODO(bogdando) add monit zabbix services monitoring, if required
  include galera::params
  class { 'zabbix':
    mysql_server_pkg => $::galera::params::mysql_server_name,
  }

} # CLUSTER_SIMPLE ENDS
# vim: set ts=2 sw=2 et :
