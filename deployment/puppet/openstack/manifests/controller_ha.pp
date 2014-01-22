#
define haproxy_service(
  $order,
  $balancers,
  $virtual_ips,
  $port,
  $define_cookies = false,
  $define_backend = false
) {
  case $name {
    "mysqld": {
      $haproxy_config_options = { 'option' => ['mysql-check user cluster_watcher', 'tcplog','clitcpka','srvtcpka'], 'balance' => 'roundrobin', 'mode' => 'tcp', 'timeout server' => '28801s', 'timeout client' => '28801s' }
      $balancermember_options = 'check inter 15s fastinter 2s downinter 1s rise 5 fall 3'
      $balancer_port = 3307
    }

    "horizon": {
      $haproxy_config_options = {
        'option'  => ['forwardfor', 'httpchk', 'httpclose', 'httplog'],
        'rspidel' => '^Set-cookie:\ IP=',
        # 'stick'   => 'on src table horizon-ssl',
        'balance' => 'source',
        'mode'    => 'http',
        'cookie'  => 'SERVERID insert indirect nocache',
        'capture' => 'cookie vgnvisitor= len 32'
      }
      $balancermember_options = 'check inter 2000 fall 3'
      $balancer_port = 80
    }

    "horizon-ssl": {
      $haproxy_config_options = {
        'option'      => ['ssl-hello-chk', 'tcpka'],
        'stick-table' => 'type ip size 200k expire 30m',
        'stick'       => 'on src',
        'balance'     => 'source',
        'timeout'     => ['client 3h', 'server 3h'],
        'mode'        => 'tcp'
      }
      $balancermember_options = 'weight 1 check'
      $balancer_port = 443
    }

    #    "rabbitmq-epmd": {
    #  $haproxy_config_options = { 'option' => ['clitcpka'], 'balance' => 'roundrobin', 'mode' => 'tcp'}
    #  $balancermember_options = 'check inter 5000 rise 2 fall 3'
    #  $balancer_port = 4369
    #}
    "rabbitmq-openstack": {
      $haproxy_config_options = { 'option' => ['tcpka'], 'timeout client' => '48h', 'timeout server' => '48h', 'balance' => 'roundrobin', 'mode' => 'tcp'}
      $balancermember_options = 'check inter 5000 rise 2 fall 3'
      $balancer_port = 5673
    }

    'radosgw': {
      $haproxy_config_options = { 'option' => ['httplog'], 'balance' => 'roundrobin' }
      $balancermember_options = 'check'
      $balancer_port = '6780'
    }

    default: {
      $haproxy_config_options = { 'option' => ['httplog'], 'balance' => 'roundrobin' }
      $balancermember_options = 'check'
      $balancer_port = $port
    }
  }

  add_haproxy_service { $name :
    order                    => $order,
    balancers                => $balancers,
    virtual_ips              => $virtual_ips,
    port                     => $port,
    haproxy_config_options   => $haproxy_config_options,
    balancer_port            => $balancer_port,
    balancermember_options   => $balancermember_options,
    define_cookies           => $define_cookies,
    define_backend           => $define_backend,
  }
}

# add_haproxy_service moved to separate define to allow adding custom sections
# to haproxy config without any default config options, except only required ones.
define add_haproxy_service (
    $order,
    $balancers,
    $virtual_ips,
    $port,
    $haproxy_config_options,
    $balancer_port,
    $balancermember_options,
    $mode = 'tcp',
    $define_cookies = false,
    $define_backend = false,
    $collect_exported = false
    ) {
    haproxy::listen { $name:
      order            => $order - 1,
      ipaddress        => $virtual_ips,
      ports            => $port,
      options          => $haproxy_config_options,
      collect_exported => $collect_exported,
      mode             => $mode,
    }
    @haproxy::balancermember { "${name}":
      order                  => $order,
      listening_service      => $name,
      balancers              => $balancers,
      balancer_port          => $balancer_port,
      balancermember_options => $balancermember_options,
      define_cookies         => $define_cookies,
      define_backend        =>  $define_backend,
    }
}

class openstack::controller_ha (
   $primary_controller,
   $controller_public_addresses, $public_interface, $private_interface = 'eth2', $controller_internal_addresses,
   $internal_virtual_ip, $public_virtual_ip, $internal_address,
   $floating_range, $fixed_range, $multi_host, $network_manager, $verbose, $debug, $network_config = {}, $num_networks = 1, $network_size = 255,
   $auto_assign_floating_ip = false, $mysql_root_password, $admin_email, $admin_user = 'admin', $admin_password, $keystone_admin_tenant='admin',
   $keystone_db_password, $keystone_admin_token, $glance_db_password, $glance_user_password, $glance_image_cache_max_size,
   $nova_db_password, $nova_user_password, $queue_provider, $rabbit_password, $rabbit_user, $rabbit_nodes,
   $qpid_password, $qpid_user, $qpid_nodes, $memcached_servers, $export_resources, $glance_backend='file', $swift_proxies=undef, $rgw_balancers=undef,
   $quantum = false,
   $quantum_config={},
   $cinder = false, $cinder_iscsi_bind_addr = false,
   $nv_physical_volume = undef, $manage_volumes = false,  $custom_mysql_setup_class = 'galera', $galera_nodes, $use_syslog = false, $syslog_log_level = 'WARNING',
   $syslog_log_facility_glance   = 'LOG_LOCAL2',
   $syslog_log_facility_cinder   = 'LOG_LOCAL3',
   $syslog_log_facility_neutron  = 'LOG_LOCAL4',
   $syslog_log_facility_nova     = 'LOG_LOCAL6',
   $syslog_log_facility_keystone = 'LOG_LOCAL7',
   $cinder_rate_limits = undef, $nova_rate_limits = undef,
   $cinder_volume_group     = 'cinder-volumes',
   $cinder_user_password    = 'cinder_user_pass',
   $cinder_db_password      = 'cinder_db_pass',
   $ceilometer                 = false,
   $ceilometer_db_password     = 'ceilometer_pass',
   $ceilometer_user_password   = 'ceilometer_pass',
   $ceilometer_metering_secret = 'ceilometer',
   $rabbit_node_ip_address  = $internal_address,
   $horizon_use_ssl         = false,
   $quantum_network_node    = false,
   $quantum_netnode_on_cnt  = false,
   $mysql_skip_name_resolve = false,
   $ha_provider             = "pacemaker",
   $create_networks         = true,
   $use_unicast_corosync    = false,
   $ha_mode                 = true,
   $nameservers             = undef,
 ) {

    # haproxy
    include haproxy::params
    $global_options   = $haproxy::params::global_options
    $defaults_options = $haproxy::params::defaults_options

    Class['cluster::haproxy'] -> Anchor['haproxy_done']

    concat { '/etc/haproxy/haproxy.cfg':
      owner   => '0',
      group   => '0',
      mode    => '0644',
    } -> Anchor['haproxy_done']


    # Dirty hack, due Puppet can't send notify between stages
    exec { 'restart_haproxy':
      command     => 'export OCF_ROOT="/usr/lib/ocf"; /usr/lib/ocf/resource.d/mirantis/haproxy reload',
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      logoutput   => true,
      refreshonly => true,
      provider    => 'shell',
      tries       => 3,
      try_sleep   => 1,
      returns     => [0, ''],
    }
    Exec['restart_haproxy'] -> Anchor['haproxy_done']
    Concat['/etc/haproxy/haproxy.cfg'] ~> Exec['restart_haproxy']

    # Simple Header
    concat::fragment { '00-header':
      target  => '/etc/haproxy/haproxy.cfg',
      order   => '01',
      content => "# This file managed by Puppet\n",
    } -> Haproxy_service<| |>

    # Template uses $global_options, $defaults_options
    concat::fragment { 'haproxy-base':
      target  => '/etc/haproxy/haproxy.cfg',
      order   => '10',
      content => template('haproxy/haproxy-base.cfg.erb'),
    } -> Haproxy_service<| |>


    Haproxy_service {
      balancers => $controller_internal_addresses
    }

    haproxy_service { 'horizon':    order => 15, port => 80, virtual_ips => [$public_virtual_ip], define_cookies => true  }

    if $horizon_use_ssl {
      haproxy_service { 'horizon-ssl': order => 17, port => 443, virtual_ips => [$public_virtual_ip] }
    }

    haproxy_service { 'keystone-1': order => 20, port => 5000, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'keystone-2': order => 30, port => 35357, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api-1': order => 40, port => 8773, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api-2': order => 50, port => 8774, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-metadata-api': order => 60, port => 8775, virtual_ips => [$internal_virtual_ip]  }

    haproxy_service { 'nova-api-4': order => 70, port => 8776, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'glance-api': order => 80, port => 9292, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }

    if $quantum {
      haproxy_service { 'quantum': order => 85, port => 9696, virtual_ips => [$public_virtual_ip, $internal_virtual_ip], define_backend => true  }
    }

    haproxy_service { 'glance-reg': order => 90, port => 9191, virtual_ips => [$internal_virtual_ip]  }

    if $queue_provider == 'rabbitmq'{
      haproxy_service { 'rabbitmq-openstack':    order => 92, port => 5672, virtual_ips => [$internal_virtual_ip], define_backend => true }
      #      haproxy_service { 'rabbitmq-epmd':    order => 91, port => 4369, virtual_ips => [$internal_virtual_ip], define_backend => true }
    }

    if $custom_mysql_setup_class == 'galera' {
      haproxy_service { 'mysqld': order => 95, port => 3306, virtual_ips => [$internal_virtual_ip], define_backend => true }
    }

    if $swift_proxies {
      haproxy_service { 'swift': order => '96', port => '8080', virtual_ips => [$public_virtual_ip,$internal_virtual_ip], balancers => $swift_proxies }
    }

    if $rgw_balancers {
      haproxy_service { 'radosgw': order => '97', port => '8080', virtual_ips => [$public_virtual_ip,$internal_virtual_ip], balancers => $rgw_balancers, define_backend => true }
    }

    if $ceilometer {
      haproxy_service { 'ceilometer': order => 98, port => 8777, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    }

    Haproxy_service<| |> ~> Exec['restart_haproxy']
    Haproxy_service<| |> -> Anchor['haproxy_done']
    Service<| title == 'haproxy' |> -> Anchor['haproxy_done']
    anchor {'haproxy_done': }

   if ( $custom_mysql_setup_class == 'galera' ) {
     ###
     # Setup Galera
     package { 'socat': ensure => present }
     exec { 'wait-for-haproxy-mysql-backend':
       command   => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep -q '^mysqld,BACKEND,.*,UP,'",
       path      => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
       try_sleep => 5,
       tries     => 60,
     }
     Package['socat'] -> Exec['wait-for-haproxy-mysql-backend']

     Exec<| title == 'wait-for-synced-state' |> -> Exec['wait-for-haproxy-mysql-backend']
     Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'initial-db-sync' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'keystone-manage db_sync' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'glance-manage db_sync' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'cinder-manage db_sync' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'nova-db-sync' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-scheduler' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-volume' |>
     Exec['wait-for-haproxy-mysql-backend'] -> Service <| title == 'cinder-api' |>
     Anchor['haproxy_done'] -> Exec['wait-for-haproxy-mysql-backend']
     Anchor['haproxy_done'] -> Class['galera']
   }

    class { '::openstack::controller':
      private_interface       => $private_interface,
      public_interface        => $public_interface,
      public_address          => $public_virtual_ip,    # It is feature for HA mode.
      internal_address        => $internal_virtual_ip,  # All internal traffic goes
      admin_address           => $internal_virtual_ip,  # through load balancer.
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      multi_host              => $multi_host,
      network_config          => $network_config,
      num_networks            => $num_networks,
      network_size            => $network_size,
      network_manager         => $network_manager,
      verbose                 => $verbose,
      debug                   => $debug,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      mysql_root_password     => $mysql_root_password,
      custom_mysql_setup_class=> $custom_mysql_setup_class,
      galera_cluster_name     => 'openstack',
      primary_controller      => $primary_controller,
      galera_node_address     => $internal_address,
      galera_nodes            => $galera_nodes,
      mysql_skip_name_resolve => $mysql_skip_name_resolve,
      admin_email             => $admin_email,
      admin_user              => $admin_user,
      admin_password          => $admin_password,
      keystone_db_password    => $keystone_db_password,
      keystone_admin_token    => $keystone_admin_token,
      keystone_admin_tenant   => $keystone_admin_tenant,
      glance_db_password      => $glance_db_password,
      glance_user_password    => $glance_user_password,
      glance_api_servers      => $glance_api_servers,
      glance_image_cache_max_size => $glance_image_cache_max_size,
      nova_db_password        => $nova_db_password,
      nova_user_password      => $nova_user_password,
      queue_provider          => $queue_provider,
      rabbit_password         => $rabbit_password,
      rabbit_user             => $rabbit_user,
      rabbit_cluster          => true,
      rabbit_nodes            => $controller_hostnames,
      rabbit_port             => '5673',
      rabbit_node_ip_address  => $rabbit_node_ip_address,
      rabbit_ha_virtual_ip    => $internal_virtual_ip,
      qpid_password           => $qpid_password,
      qpid_user               => $qpid_user,
      qpid_nodes              => $qpid_nodes,
      qpid_port               => '5672',
      qpid_node_ip_address    => $rabbit_node_ip_address,
      cache_server_ip         => $memcached_servers,
      export_resources        => false,
      api_bind_address        => $internal_address,
      db_host                 => $internal_virtual_ip,
      service_endpoint        => $internal_virtual_ip,
      glance_backend          => $glance_backend,
      #require                 => Service['keepalived'],
      quantum                 => $quantum,
      quantum_config          => $quantum_config,
      quantum_network_node    => $quantum_network_node,
      quantum_netnode_on_cnt  => $quantum_netnode_on_cnt,
      segment_range           => $segment_range,
      tenant_network_type     => $tenant_network_type,
      cinder                  => $cinder,
      cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
      cinder_user_password    => $cinder_user_password,
      cinder_db_password      => $cinder_db_password,
      manage_volumes          => $manage_volumes,
      nv_physical_volume      => $nv_physical_volume,
      cinder_volume_group     => $cinder_volume_group,
      ceilometer              => $ceilometer,
      ceilometer_db_password  => $ceilometer_db_password,
      ceilometer_user_password => $ceilometer_user_password,
      ceilometer_metering_secret => $ceilometer_metering_secret,
      # turn on SWIFT_ENABLED option for Horizon dashboard
      swift                        => $glance_backend ? { 'swift'    => true, default => false },
      use_syslog                   => $use_syslog,
      syslog_log_level             => $syslog_log_level,
      syslog_log_facility_glance   => $syslog_log_facility_glance,
      syslog_log_facility_cinder   => $syslog_log_facility_cinder,
      syslog_log_facility_nova     => $syslog_log_facility_nova,
      syslog_log_facility_keystone => $syslog_log_facility_keystone,
      cinder_rate_limits           => $cinder_rate_limits,
      nova_rate_limits             => $nova_rate_limits,
      horizon_use_ssl              => $horizon_use_ssl,
      ha_mode                      => $ha_mode,
      nameservers                  => $nameservers,
    }
    if $quantum and $quantum_network_node {
      class { '::openstack::neutron_router':
        #service_endpoint      => $internal_virtual_ip,
        #auth_host             => $internal_virtual_ip,
        #nova_api_vip          => $internal_virtual_ip,
        #private_interface     => $private_interface,
        #segment_range         => $segment_range,
        #internal_address      => $internal_address,
        #public_interface      => $public_interface,
        #create_networks       => $create_networks,
        verbose               => $verbose,
        debug                 => $debug,
        neutron               => $quantum,
        neutron_config        => $quantum_config,
        neutron_network_node  => $quantum_network_node,
        #neutron_netnode_on_cnt=> $quantum_netnode_on_cnt,
        service_provider      => $ha_provider,
        use_syslog            => $use_syslog,
        syslog_log_level      => $syslog_log_level,
        syslog_log_facility   => $syslog_log_facility_neutron,
        ha_mode               => $ha_mode,
      }
    }
    class { 'openstack::auth_file':
      admin_user              => $admin_user,
      admin_password          => $admin_password,
      admin_tenant            => $keystone_admin_tenant,
      keystone_admin_token    => $keystone_admin_token,
      controller_node         => $internal_virtual_ip,
    }
}

