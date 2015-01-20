class osnailyfacter::cluster_ha {

  ##PARAMETERS DERIVED FROM YAML FILE

  $primary_controller = $::fuel_settings['role'] ? { 'primary-controller'=>true, default=>false }

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
    $ext_mongo = false
  } else {
    $ceilometer_hash = $::fuel_settings['ceilometer']

    # External mongo integration
    if has_key($::fuel_settings, 'mongo') and $::fuel_settings['mongo']['enabled'] {
      $ext_mongo_hash = $::fuel_settings['external_mongo']
      $ceilometer_db_user = $ext_mongo_hash['mongo_user']
      $ceilometer_db_password = $ext_mongo_hash['mongo_password']
      $ceilometer_db_name = $ext_mongo_hash['mongo_db_name']
      $ext_mongo = true
    } else {
      $ceilometer_db_user = 'ceilometer'
      $ceilometer_db_password = $ceilometer_hash['db_password']
      $ceilometer_db_name = 'ceilometer'
      $ext_mongo = false
      $ext_mongo_hash = {}
    }
  }

  # vCenter integration

  if $::fuel_settings['libvirt_type'] == 'vcenter' {
    $vcenter_hash = $::fuel_settings['vcenter']
  } else {
    $vcenter_hash = {}
  }

  if $primary_controller {
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
  $mp_hash              = $::fuel_settings['mp']
  $network_manager      = "nova.network.manager.${novanetwork_params['network_manager']}"

  if $ext_mongo {
    $mongo_hosts = $ext_mongo_hash['hosts_ip']
    if $ext_mongo_hash['mongo_replset'] {
      $mongo_replicaset = $ext_mongo_hash['mongo_replset']
    } else {
      $mongo_replicaset = undef
    }
  } elsif $ceilometer_hash['enabled'] {
    $mongo_hosts = mongo_hosts($nodes_hash)
    if size(mongo_hosts($nodes_hash, 'array', 'mongo')) > 1 {
      $mongo_replicaset = 'ceilometer'
    } else {
      $mongo_replicaset = undef
    }
  }

  if !$rabbit_hash['user'] {
    $rabbit_hash['user'] = 'nova'
  }

  if ! $::use_neutron {
    $floating_ips_range = $::fuel_settings['floating_network_range']
  }
  $floating_hash = {}

  ##CALCULATED PARAMETERS


  ##NO NEED TO CHANGE

  $node = filter_nodes($nodes_hash,'name',$::hostname)
  if empty($node) {
    fail("Node $::hostname is not defined in the hash structure")
  }

  # get cidr netmasks for VIPs
  $primary_controller_nodes = filter_nodes($nodes_hash,'role','primary-controller')
  $vip_management_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['internal_netmask'])
  $vip_public_cidr_netmask = netmask_to_cidr($primary_controller_nodes[0]['public_netmask'])

  if $::use_neutron {
    $vip_mgmt_other_nets = join($::fuel_settings['network_scheme']['endpoints']["$::internal_int"]['other_nets'], ' ')
  }

  $vips = { # Do not convert to ARRAY, It can't work in 2.7
    management   => {
      namespace            => 'haproxy',
      nic                  => $::internal_int,
      base_veth            => "${::internal_int}-hapr",
      ns_veth              => "hapr-m",
      ip                   => $::fuel_settings['management_vip'],
      cidr_netmask         => $vip_management_cidr_netmask,
      gateway              => 'link',
      gateway_metric       => '20',
      other_networks       => $vip_mgmt_other_nets,
      iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${::internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -I POSTROUTING -m mark --mark 0x2b ! -o ${::internal_int} -j MASQUERADE",
      iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${::internal_int}-hapr -j MARK --set-mark 0x2b ; iptables -t nat -D POSTROUTING -m mark --mark 0x2b ! -o ${::internal_int} -j MASQUERADE",
      iptables_comment     => "masquerade-for-management-net",
      tie_with_ping        => false,
      ping_host_list       => "",
    },
  }

  if $::public_int {

    if $::use_neutron{
      $vip_publ_other_nets = join($::fuel_settings['network_scheme']['endpoints']["$::public_int"]['other_nets'], ' ')
    }

    $run_ping_checker = $::fuel_settings['run_ping_checker'] ? { 'false' => false, default =>true }

    $vips[public] = {
      namespace            => 'haproxy',
      nic                  => $::public_int,
      base_veth            => "${::public_int}-hapr",
      ns_veth              => "hapr-p",
      ip                   => $::fuel_settings['public_vip'],
      cidr_netmask         => $vip_public_cidr_netmask,
      gateway              => 'link',
      gateway_metric       => '10',
      other_networks       => $vip_publ_other_nets,
      iptables_start_rules => "iptables -t mangle -I PREROUTING -i ${::public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -I POSTROUTING -m mark --mark 0x2a ! -o ${::public_int} -j MASQUERADE",
      iptables_stop_rules  => "iptables -t mangle -D PREROUTING -i ${::public_int}-hapr -j MARK --set-mark 0x2a ; iptables -t nat -D POSTROUTING -m mark --mark 0x2a ! -o ${::public_int} -j MASQUERADE",
      iptables_comment     => "masquerade-for-public-net",
      tie_with_ping        => $run_ping_checker,
      ping_host_list       => $::use_neutron ? {
        default => $::fuel_settings['network_data'][$::public_int]['gateway'],
        true    => $::fuel_settings['network_scheme']['endpoints']['br-ex']['gateway'],
      },
    }
  }
  $vip_keys = keys($vips)

  ##REFACTORING NEEDED


  ##TODO: simply parse nodes array
  $controllers = concat($primary_controller_nodes, filter_nodes($nodes_hash,'role','controller'))
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
    $amqp_nodes = concat(['127.0.0.1'], fqdn_rotate(delete($controller_nodes, $::internal_address)))
  } else {
    $amqp_nodes = fqdn_rotate($controller_nodes)
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
    $glance_backend = 'swift'
    $glance_known_stores = [ 'glance.store.swift.Store', 'glance.store.http.Store' ]
  }

  if ($::use_ceph) {
    $primary_mons   = $controllers
    $primary_mon    = $controllers[0]['name']

    if ($::use_neutron) {
      $ceph_cluster_network = get_network_role_property('storage', 'cidr')
      $ceph_public_network  = get_network_role_property('management', 'cidr')
    } else {
      $ceph_cluster_network = $::fuel_settings['storage_network_range']
      $ceph_public_network = $::fuel_settings['management_network_range']
    }

    class {'ceph':
      primary_mon          => $primary_mon,
      cluster_node_address => $controller_node_public,
      use_rgw              => $storage_hash['objects_ceph'],
      glance_backend       => $glance_backend,
      rgw_pub_ip           => $::fuel_settings['public_vip'],
      rgw_adm_ip           => $::fuel_settings['management_vip'],
      rgw_int_ip           => $::fuel_settings['management_vip'],
      cluster_network      => $ceph_cluster_network,
      public_network       => $ceph_public_network,
      use_syslog           => $::use_syslog,
      syslog_log_level     => $syslog_log_level,
      syslog_log_facility  => $::syslog_log_facility_ceph,
    }
  }

  # Use Swift if it isn't replaced by vCenter, Ceph for BOTH images and objects
  if !($storage_hash['images_ceph'] and $storage_hash['objects_ceph']) and !$storage_hash['images_vcenter'] {
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
    $master_swift_proxy_ip    = $master_swift_proxy_nodes[0]['storage_address']
    #$master_hostname         = $master_swift_proxy_nodes[0]['name']
    $swift_loopback = false
    if $primary_controller {
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

  # NOTE(bogdando) for controller nodes running Corosync with Pacemaker
  #   we delegate all of the monitor functions to RA instead of monit.
  if member($roles, 'controller') or member($roles, 'primary-controller') {
    $use_monit_real = false
  } else {
    $use_monit_real = $::use_monit
  }

  if $use_monit_real {
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

  #HARDCODED PARAMETERS

  $multi_host              = true
  $mirror_type = 'external'
  Exec { logoutput => true }

  if $use_vmware_nsx {
    class { 'plugin_neutronnsx':
      neutron_config     => $neutron_config,
      neutron_nsx_config => $neutron_nsx_config,
      roles              => $roles,
    }
  }

  # ROLE CASE STARTS
  case $::fuel_settings['role'] {
    "compute" : {
      include osnailyfacter::test_compute

      if ($::mellanox_mode == 'ethernet') {
        $net04_physnet = $neutron_config['predefined_networks']['net04']['L2']['physnet']
        class { 'mellanox_openstack::compute':
          physnet => $net04_physnet,
          physifc => $::fuel_settings['neutron_mellanox']['physical_port'],
        }
      }

      class { 'openstack::compute':
        public_interface            => $::public_int ? { undef=>'', default=>$::public_int },
        private_interface           => $::use_neutron ? { true=>false, default=>$::fuel_settings['fixed_interface'] },
        internal_address            => $::internal_address,
        libvirt_type                => $::fuel_settings['libvirt_type'],
        fixed_range                 => $::use_neutron ? { true=>false, default=>$::fuel_settings['fixed_network_range']},
        network_manager             => $network_manager,
        network_config              => $network_config,
        multi_host                  => $multi_host,
        sql_connection              => "mysql://nova:${nova_hash[db_password]}@${::fuel_settings['management_vip']}/nova?read_timeout=60",
        queue_provider              => $::queue_provider,
        amqp_hosts                  => $amqp_hosts,
        amqp_user                   => $rabbit_hash['user'],
        amqp_password               => $rabbit_hash['password'],
        rabbit_ha_queues            => $rabbit_ha_queues,
        auto_assign_floating_ip     => $::fuel_settings['auto_assign_floating_ip'],
        glance_api_servers          => "${::fuel_settings['management_vip']}:9292",
        vncproxy_host               => $::fuel_settings['public_vip'],
        vncserver_listen            => '0.0.0.0',
        debug                       => $::debug,
        verbose                     => $::verbose,
        cinder_volume_group         => "cinder",
        vnc_enabled                 => true,
        manage_volumes              => $manage_volumes,
        nova_user_password          => $nova_hash[user_password],
        cache_server_ip             => $controller_nodes,
        service_endpoint            => $::fuel_settings['management_vip'],
        cinder                      => true,
        cinder_iscsi_bind_addr      => $cinder_iscsi_bind_addr,
        cinder_user_password        => $cinder_hash[user_password],
        cinder_db_password          => $cinder_hash[db_password],
        ceilometer                  => $ceilometer_hash[enabled],
        ceilometer_metering_secret  => $ceilometer_hash[metering_secret],
        ceilometer_user_password    => $ceilometer_hash[user_password],
        db_host                     => $::fuel_settings['management_vip'],

        network_provider            => $::osnailyfacter::cluster_ha::network_provider,
        neutron_user_password       => $::osnailyfacter::cluster_ha::neutron_user_password,
        base_mac                    => $::osnailyfacter::cluster_ha::base_mac,

        use_syslog                  => $use_syslog,
        syslog_log_facility         => $::syslog_log_facility_nova,
        syslog_log_facility_neutron => $::syslog_log_facility_neutron,
        nova_rate_limits            => $::nova_rate_limits,
        nova_report_interval        => $::nova_report_interval,
        nova_service_down_time      => $::nova_service_down_time,
        state_path                  => $nova_hash[state_path],
      }

      if ($::use_ceph){
        Class['openstack::compute'] -> Class['ceph']
      }

      #TODO: PUT this configuration stanza into nova class
      nova_config { 'DEFAULT/start_guests_on_host_boot': value => $::fuel_settings['start_guests_on_host_boot'] }
      nova_config { 'DEFAULT/use_cow_images': value => $::fuel_settings['use_cow_images'] }
      nova_config { 'DEFAULT/compute_scheduler_driver': value => $::fuel_settings['compute_scheduler_driver'] }

    # Configure monit watchdogs
    # FIXME(bogdando) replace service_path and action to systemd, once supported
    if $use_monit_real {
      monit::process { $nova_compute_name :
        ensure        => running,
        matching      => '/usr/bin/python /usr/bin/nova-compute',
        start_command => "${service_path} ${nova_compute_name} restart",
        stop_command  => "${service_path} ${nova_compute_name} stop",
        pidfile       => false,
      }
      if $::use_neutron {
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
      if !$ext_mongo {
        class { 'openstack::mongo_secondary':
          mongodb_bind_address        => [ '127.0.0.1', $::internal_address ],
          use_syslog                  => $use_syslog,
          debug                       => $debug,
        }
      }
    } # MONGO ENDS

    "primary-mongo" : {
      if !$ext_mongo {
        class { 'openstack::mongo_primary':
          mongodb_bind_address        => [ '127.0.0.1', $::internal_address ],
          ceilometer_metering_secret  => $ceilometer_hash['metering_secret'],
          ceilometer_db_password      => $ceilometer_db_password,
          ceilometer_replset_members  => mongo_hosts($nodes_hash, 'array', 'mongo'),
          replset                     => $mongo_replicaset,
          use_syslog                  => $use_syslog,
          debug                       => $debug,
        }
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
        iser                 => $storage_hash['iser'],
        enabled              => true,
        auth_host            => $::fuel_settings['management_vip'],
        iscsi_bind_host      => $::storage_address,
        cinder_user_password => $cinder_hash[user_password],
        syslog_log_facility  => $::syslog_log_facility_cinder,
        debug                => $::debug,
        verbose              => $::verbose,
        use_syslog           => $::use_syslog,
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
      if $use_monit_real {
        monit::process { $cinder_volume_name :
          ensure        => running,
          matching      => '/usr/bin/python /usr/bin/cinder-volume',
          start_command => "${service_path} ${cinder_volume_name} restart",
          stop_command  => "${service_path} ${cinder_volume_name} stop",
          pidfile       => false,
        }
      }
    } # CINDER ENDS

    "ceph-osd" : {
      #Class Ceph is already defined so it will do it's thing.
      notify {"ceph_osd: ${::ceph::osd_devices}": }
      notify {"osd_devices:  ${::osd_devices_list}": }
      # TODO(bogdando) add monit ceph-osd services monitoring, if required
    } # CEPH-OSD ENDS

    # Definition of the first OpenStack Swift node.
    /storage/ : {
      class { 'operatingsystem::checksupported':
          stage => 'setup'
      }

      $swift_zone = $node[0]['swift_zone']

      class { 'openstack::swift::storage_node':
        storage_type               => $swift_loopback,
        loopback_size              => '5243780',
        storage_mnt_base_dir       => $swift_partition,
        storage_devices            =>  $mountpoints,
        swift_zone                 => $swift_zone,
        swift_local_net_ip         => $swift_local_net_ip,
        master_swift_proxy_ip      => $master_swift_proxy_ip,
        cinder                     => $cinder,
        cinder_iscsi_bind_addr     => $cinder_iscsi_bind_addr,
        cinder_volume_group        => "cinder",
        manage_volumes             => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
        db_host                    => $::fuel_settings['management_vip'],
        service_endpoint           => $::fuel_settings['management_vip'],
        cinder_rate_limits         => $cinder_rate_limits,
        queue_provider             => $::queue_provider,
        rabbit_nodes               => $controller_nodes,
        rabbit_password            => $rabbit_hash[password],
        rabbit_user                => $rabbit_hash[user],
        rabbit_ha_virtual_ip       => $::fuel_settings['management_vip'],
        qpid_password              => $rabbit_hash[password],
        qpid_user                  => $rabbit_hash[user],
        qpid_nodes                 => [$::fuel_settings['management_vip']],
        sync_rings                 => ! $primary_proxy,
        syslog_log_level           => $syslog_log_level,
        debug                      => $debug,
        verbose                    => $verbose,
        syslog_log_facility_cinder => $syslog_log_facility_cinder,
        log_facility               => 'LOG_SYSLOG',
      }

      # TODO(bogdando) add monit swift-storage services monitoring, if required
      # NOTE(bogdando) we don't deploy swift as a separate role for now, but will do
    }

    # Definition of OpenStack Swift proxy nodes.
    /swift-proxy/ : {
      class { 'operatingsystem::checksupported':
          stage => 'first'
      }

      if $primary_proxy {
        ring_devices {'all':
          storages => $swift_storages,
          require  => Class['swift'],
        }
      }

      class { 'openstack::swift::proxy':
        swift_user_password     => $swift_hash[user_password],
        swift_proxies           => $swift_proxies,
        primary_proxy           => $primary_proxy,
        controller_node_address => $::fuel_settings['management_vip'],
        swift_local_net_ip      => $swift_local_net_ip,
        master_swift_proxy_ip   => $master_swift_proxy_ip,
        syslog_log_level        => $syslog_log_level,
        debug                   => $debug,
        verbose                 => $verbose,
        log_facility            => 'LOG_SYSLOG',
      }
    }

  } # ROLE CASE ENDS

  # TODO(bogdando) add monit zabbix services monitoring, if required
  # NOTE(bogdando) for nodes with pacemaker, we should use OCF instead of monit
  include galera::params
  class { 'zabbix':
    mysql_server_pkg => $::galera::params::mysql_server_name,
  }

  package { 'screen':
    ensure => present,
  }

  # Make corosync and pacemaker setup and configuration before all services provided by pacemaker
  Class['openstack::corosync'] -> Service<| provider=='pacemaker' |>

} # CLUSTER_HA ENDS
# vim: set ts=2 sw=2 et :
