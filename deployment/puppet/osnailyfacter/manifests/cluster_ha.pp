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

  # All hash assignment from a dimensional hash must be in the local scope or
  # they will be undefined (don't move to site.pp)

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
    management_vrouter => {
      namespace            => 'vrouter',
      nic                  => $::internal_int,
      base_veth            => "${::internal_int}-vrouter",
      ns                   => 'vrouter',
      ns_veth              => "vr-mgmt",
      ip                   => '10.108.12.104',  ### TO BE PASSED FORM ASTUTE
      cidr_netmask         => '24',             ### TO BE PASSED FORM ASTUTE
      gateway              => 'none',
      gateway_metric       => '0',
      bridge               => 'br-mgmt',        ### TO BE PASSED FORM ASTUTE
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
    $vips[public_vrouter] = {
      namespace            => 'vrouter',
      nic                  => $::public_int,
      base_veth            => "${::public_int}-vrouter",
      ns_veth              => "vr-ex",
      ns                   => 'vrouter',
      ip                   => '10.108.11.104',                       ### TO BE PASSED FORM ASTUTE
      cidr_netmask         => '24',                                  ### TO BE PASSED FORM ASTUTE
      gateway              => '10.108.11.1',                         ### TO BE PASSED FORM ASTUTE
      gateway_metric       => '0',
      bridge               => 'br-ex',                               ### TO BE PASSED FORM ASTUTE
      ns_iptables_start_rules => "iptables -t nat -A POSTROUTING -o br-ex -j MASQUERADE",              ### TO BE PASSED FORM ASTUTE
      ns_iptables_stop_rules  => "iptables -t nat -D POSTROUTING -o br-ex -j MASQUERADE",              ### TO BE PASSED FORM ASTUTE
      tie_with_ping        => $run_ping_checker,
      ping_host_list       => $::use_neutron ? {
        #default => $::fuel_settings['network_data'][$::public_int]['gateway'],
        default => $::fuel_settings['network_scheme']['endpoints']['br-ex']['gateway'],
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

  if ($::use_ceph and !(($::fuel_settings['role'] == 'cinder') and $storage_hash['volumes_lvm'])) {
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
