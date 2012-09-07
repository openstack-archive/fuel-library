define haproxy_service($order, $hostnames, $balancer_ips, $virtual_ip, $port) {
  haproxy::config { $name:
    order => $order - 1,
    virtual_ip => $virtual_ip,
    virtual_ip_port => $port,
      haproxy_config_options => {
        'option' => ['tcplog'], 'balance' => 'roundrobin' },
  }
  @haproxy::balancermember { "${name}":
    order                  => $order,
    listening_service      => $name,
    server_name            => $hostnames,
    balancer_ip            => $balancer_ips,
    balancer_port          => $port,
    balancermember_options => 'check'
  }
}
class openstack::controller_ha (
   $master_hostname,
   $controller_public_addresses, $public_interface, $private_interface, $controller_internal_addresses,
   $virtual_ip, $internal_interface,
   $floating_range, $fixed_range, $multi_host, $network_manager, $verbose,
   $auto_assign_floating_ip, $mysql_root_password, $admin_email, $admin_password,
   $keystone_db_password, $keystone_admin_token, $glance_db_password, $glance_user_password,
   $nova_db_password, $nova_user_password, $rabbit_password, $rabbit_user,
   $rabbit_nodes, $export_resources
 ) {
    $which = $::hostname ? { $master_hostname => 0, default => 1 }

    $vip = $virtual_ip
    $hosts = $controller_hostnames
    $ips = $controller_internal_addresses
    # haproxy
    haproxy_service { 'keystone-1': order => 20, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 5000 }
    haproxy_service { 'keystone-2': order => 30, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 35357 }
    haproxy_service { 'nova-api-1': order => 40, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 8773 }
    haproxy_service { 'nova-api-2': order => 50, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 8774 }
    haproxy_service { 'nova-api-3': order => 60, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 8775 }
    haproxy_service { 'nova-api-4': order => 70, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 8776 }
    haproxy_service { 'glance-api': order => 80, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 9292 }
    haproxy_service { 'glance-reg': order => 90, virtual_ip => $vip, hostnames => $hosts, balancer_ips => $ips, port => 9191 }

    if $which == 0 {
      exec { 'create-virtual-ip':
        command => "ip addr add ${virtual_ip} dev ${internal_interface}",
        unless => "ip addr show dev ${internal_interface} | grep ${virtual_ip}",
        path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      }
    }

    sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }

    $internal_address = $controller_internal_addresses[$which]
    class { 'haproxy':
      enable => true, 
      haproxy_global_options   => {'log'      => "${internal_address} local0",
                                  'chroot'  => '/var/lib/haproxy',
                                  'pidfile' => '/var/run/haproxy.pid',
                                  'maxconn' => '4000',
                                  'user'    => 'haproxy',
                                  'group'   => 'haproxy',
                                  'daemon'  => '',
                                  'stats'   => 'socket /var/lib/haproxy/stats'
                                  },
      haproxy_defaults_options => {'log'      => 'global',
                                    'stats'   => 'enable',
                                    'mode'    => 'http',
                                    'option'  => 'redispatch',
                                    'retries' => '3',
                                    'timeout' => ['http-request 10s',
                                    'queue 1m',
                                    'connect 10s',
                                    'client 1m',
                                    'server 1m',
                                    'check 10s'],
                                    'maxconn' => '8000'
                                  },
       require => Sysctl::Value['net.ipv4.ip_nonlocal_bind'],
    }

    # keepalived
    class { 'keepalived': require => Class['haproxy'] }
    keepalived::instance { '42':
      interface => $internal_interface,
      virtual_ips => [$virtual_ip],
      state    => $which ? { 0 => 'MASTER', default => 'BACKUP' },
      priority => $which ? { 0 => 101,      default => 100      },
    }

    class { 'galera':
      cluster_name => 'openstack',
      master_ip => $which ? { 0 => false, default => $controller_internal_addresses[0] },
      node_address => $controller_internal_addresses[$which],
    }

    class { 'openstack::controller':
      public_address          => $virtual_ip,
      public_interface        => $public_interface,
      private_interface       => $private_interface,
      internal_address        => $virtual_ip,
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      multi_host              => $multi_host,
      network_manager         => $network_manager,
      verbose                 => $verbose,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      mysql_root_password     => $mysql_root_password,
      custom_mysql_setup_class => 'galera',
      admin_email             => $admin_email,
      admin_password          => $admin_password,
      keystone_db_password    => $keystone_db_password,
      keystone_admin_token    => $keystone_admin_token,
      glance_db_password      => $glance_db_password,
      glance_user_password    => $glance_user_password,
      nova_db_password        => $nova_db_password,
      nova_user_password      => $nova_user_password,
      rabbit_password         => $rabbit_password,
      rabbit_user             => $rabbit_user,
      rabbit_cluster          => true,
      rabbit_nodes            => $controller_hostnames,
      export_resources        => false,
      api_bind_address        => $controller_internal_addresses[$which],
      mysql_host              => $virtual_ip,
      service_endpoint        => $virtual_ip,
    }

    class { 'openstack::auth_file':
      admin_password          => $admin_password,
      keystone_admin_token    => $keystone_admin_token,
      controller_node         => $virtual_ip,
    }
}

