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
        'balance' => 'roundrobin',
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

    "rabbitmq-epmd": {
      $haproxy_config_options = { 'option' => ['clitcpka'], 'balance' => 'roundrobin', 'mode' => 'tcp'}
      $balancermember_options = 'check inter 5000 rise 2 fall 3'
      $balancer_port = 4369
    }
    "rabbitmq-openstack": {
      $haproxy_config_options = { 'option' => ['tcpka'], 'timeout client' => '48h', 'timeout server' => '48h', 'balance' => 'roundrobin', 'mode' => 'tcp'}
      $balancermember_options = 'check inter 5000 rise 2 fall 3'
      $balancer_port = 5673
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
   $controller_public_addresses, $public_interface, $private_interface, $controller_internal_addresses,
   $internal_virtual_ip, $public_virtual_ip, $internal_interface, $internal_address,
   $floating_range, $fixed_range, $multi_host, $network_manager, $verbose, $debug, $network_config = {}, $num_networks = 1, $network_size = 255,
   $auto_assign_floating_ip, $mysql_root_password, $admin_email, $admin_user = 'admin', $admin_password, $keystone_admin_tenant='admin',
   $keystone_db_password, $keystone_admin_token, $glance_db_password, $glance_user_password,
   $nova_db_password, $nova_user_password, $queue_provider, $rabbit_password, $rabbit_user, $rabbit_nodes,
   $qpid_password, $qpid_user, $qpid_nodes, $memcached_servers, $export_resources, $glance_backend='file', $swift_proxies=undef,
   $quantum = false, $quantum_user_password='', $quantum_db_password='', $quantum_db_user = 'quantum',
   $quantum_db_dbname  = 'quantum', $cinder = false, $cinder_iscsi_bind_addr = false, $tenant_network_type = 'gre', $segment_range = '1:4094',
   $nv_physical_volume = undef, $manage_volumes = false,$galera_nodes, $use_syslog = false, $syslog_log_level = 'WARNING',
   $syslog_log_facility_glance   = 'LOCAL2',
   $syslog_log_facility_cinder   = 'LOCAL3',
   $syslog_log_facility_quantum  = 'LOCAL4',
   $syslog_log_facility_nova     = 'LOCAL6',
   $syslog_log_facility_keystone = 'LOCAL7',
   $cinder_rate_limits = undef, $nova_rate_limits = undef,
   $cinder_volume_group     = 'cinder-volumes',
   $cinder_user_password    = 'cinder_user_pass',
   $cinder_db_password      = 'cinder_db_pass',
   $rabbit_node_ip_address  = $internal_address,
   $horizon_use_ssl         = false,
   $quantum_network_node    = false,
   $quantum_netnode_on_cnt  = false,
   $quantum_gre_bind_addr   = $internal_address,
   $quantum_external_ipinfo = {},
   $mysql_skip_name_resolve = false,
   $ha_provider             = "pacemaker",
   $create_networks         = true,
   $use_unicast_corosync    = false,
   $ha_mode                 = true,
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
      command     => 'crm resource restart clone_p_haproxy',
      path        => '/usr/bin:/usr/sbin:/bin:/sbin',
      logoutput   => true,
      refreshonly => true,
      tries       => 3,
      try_sleep   => 1,
      #returns    => [0, 1, ''],
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
      haproxy_service { 'rabbitmq-epmd':    order => 91, port => 4369, virtual_ips => [$internal_virtual_ip], define_backend => true }
    }

    haproxy_service { 'mysqld': order => 95, port => 3306, virtual_ips => [$internal_virtual_ip], define_backend => true }
    if $glance_backend == 'swift' {
      haproxy_service { 'swift': order => 96, port => 8080, virtual_ips => [$public_virtual_ip,$internal_virtual_ip], balancers => $swift_proxies }
    }

    Haproxy_service<| |> ~> Exec['restart_haproxy']
    Haproxy_service<| |> -> Anchor['haproxy_done']
    Service<| title == 'haproxy' |> -> Anchor['haproxy_done']

    anchor {'haproxy_done': }


    ###
    # Setup Galera's

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
      custom_mysql_setup_class=> 'galera',
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
      nova_db_password        => $nova_db_password,
      nova_user_password      => $nova_user_password,
      queue_provider          => 'qpid',
      rabbit_password         => $rabbit_password,
      rabbit_user             => $rabbit_user,
      rabbit_cluster          => true,
      rabbit_nodes            => $controller_hostnames,
      rabbit_port             => '5673',
      rabbit_node_ip_address  => $rabbit_node_ip_address,
      rabbit_ha_virtual_ip    => $internal_virtual_ip,
      qpid_password           => $rabbit_hash[password],
      qpid_user               => $rabbit_user,
      qpid_cluster            => true,
      qpid_nodes              => $controller_hostnames,
      qpid_port               => '5673',
      qpid_node_ip_address    => $rabbit_node_ip_address,
      cache_server_ip         => $memcached_servers,
      export_resources        => false,
      api_bind_address        => $internal_address,
      db_host                 => $internal_virtual_ip,
      service_endpoint        => $internal_virtual_ip,
      glance_backend          => $glance_backend,
      #require                 => Service['keepalived'],
      quantum                 => $quantum,
      quantum_user_password   => $quantum_user_password,
      quantum_db_password     => $quantum_db_password,
      quantum_gre_bind_addr   => $quantum_gre_bind_addr,
      quantum_external_ipinfo => $quantum_external_ipinfo,
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
      # turn on SWIFT_ENABLED option for Horizon dashboard
      swift                   => $glance_backend ? { 'swift' => true, default => false },
      use_syslog              => $use_syslog,
      syslog_log_level        => $syslog_log_level,
      syslog_log_facility_glance   => $syslog_log_facility_glance,
      syslog_log_facility_cinder => $syslog_log_facility_cinder,
      syslog_log_facility_nova => $syslog_log_facility_nova,
      syslog_log_facility_keystone => $syslog_log_facility_keystone,
      cinder_rate_limits      => $cinder_rate_limits,
      nova_rate_limits        => $nova_rate_limits,
      horizon_use_ssl         => $horizon_use_ssl,
      ha_mode                 => $ha_mode,
    }
    if $quantum and $quantum_network_node {
      class { '::openstack::quantum_router':
        db_host               => $internal_virtual_ip,
        service_endpoint      => $internal_virtual_ip,
        auth_host             => $internal_virtual_ip,
        nova_api_vip          => $internal_virtual_ip,
        internal_address      => $internal_address,
        public_interface      => $public_interface,
        private_interface     => $private_interface,
        floating_range        => $floating_range,
        fixed_range           => $fixed_range,
        create_networks       => $create_networks,
        verbose               => $verbose,
        debug                 => $debug,
        queue_provider        => $queue_provider,
        rabbit_password       => $rabbit_password,
        rabbit_user           => $rabbit_user,
        rabbit_nodes          => $rabbit_nodes,
        rabbit_ha_virtual_ip  => $internal_virtual_ip,
        qpid_password         => $rabbit_hash[password],
        qpid_user             => $rabbit_user,
        qpid_nodes            => $controller_hostnames,
        quantum               => $quantum,
        quantum_user_password => $quantum_user_password,
        quantum_db_password   => $quantum_db_password,
        quantum_db_user       => $quantum_db_user,
        quantum_db_dbname     => $quantum_db_dbname,
        quantum_gre_bind_addr => $quantum_gre_bind_addr,
        quantum_network_node  => $quantum_network_node,
        quantum_netnode_on_cnt=> $quantum_netnode_on_cnt,
        service_provider      => $ha_provider,
        tenant_network_type   => $tenant_network_type,
        segment_range         => $segment_range,
        external_ipinfo       => $external_ipinfo,
        api_bind_address      => $internal_address,
        use_syslog            => $use_syslog,
        syslog_log_level      => $syslog_log_level,
        syslog_log_facility   => $syslog_log_facility_quantum,
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
    if $ha_provider == 'pacemaker' {
      if $use_unicast_corosync {
        $unicast_addresses = $controller_internal_addresses
      } else {
        $unicast_addresses = undef
      }
      class {'openstack::corosync':
        bind_address => $internal_address,
        unicast_addresses => $unicast_addresses,
        before => Class['qpid::server'],
      }
    }
}

