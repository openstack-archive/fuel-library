define haproxy_service($order, $hostnames, $balancer_ips, $virtual_ips, $port, $define_cookies = false) {

  case $name {
    "mysqld": {
      $haproxy_config_options = { 'option' => ['mysql-check user cluster_watcher'], 'balance' => 'roundrobin', 'mode' => 'tcp' }
      $balancermember_options = 'check inter 15s fastinter 2s downinter 1s rise 5 fall 3'
      $balancer_port = 3307
    }
    "horizon": {
      $haproxy_config_options = { 'option' => ['forwardfor','httpchk','httpclose'],'rspidel'=>'^Set-cookie:\ IP=', 'balance' => 'roundrobin', 'cookie'=>'SERVERID insert indirect nocache', 'capture'=>'cookie vgnvisitor= len 32'}
      $balancermember_options = 'check inter 2000 fall 3'
      $balancer_port = 80
    }

    default: {
      $haproxy_config_options = { 'option' => ['tcplog'], 'balance' => 'roundrobin' }
      $balancermember_options = 'check'
      $balancer_port = $port
    }
  }

  haproxy::config { $name:
    order => $order - 1,
    virtual_ips => $virtual_ips,
    virtual_ip_port => $port,
    haproxy_config_options => $haproxy_config_options,
  }

  @haproxy::balancermember { "${name}":
    order                  => $order,
    listening_service      => $name,
    server_name            => $hostnames,
    balancer_ip            => $balancer_ips,
    balancer_port          => $balancer_port,
    balancermember_options => $balancermember_options,
    define_cookies        => $define_cookies
  }

}

define keepalived_dhcp_hook($interface)
{
    $down_hook="ip addr show dev $interface | grep keepalived | awk '{print \$2}' > /tmp/keepalived_${interface}_ip\n"
    $up_hook="cat /tmp/keepalived_${interface}_ip |  while read ip; do  ip addr add \$ip dev $interface label $interface:keepalived; done\n"
    file {"/etc/dhcp/dhclient-${interface}-down-hooks": content=>$down_hook, mode => 744 }
    file {"/etc/dhcp/dhclient-${interface}-up-hooks": content=>$up_hook, mode => 744 }
}



class openstack::controller_ha (
   $master_hostname,
   $controller_public_addresses, $public_interface, $private_interface, $controller_internal_addresses,
   $internal_virtual_ip, $public_virtual_ip, $internal_interface,
   $floating_range, $fixed_range, $multi_host, $network_manager, $verbose,
   $auto_assign_floating_ip, $mysql_root_password, $admin_email, $admin_password,
   $keystone_db_password, $keystone_admin_token, $glance_db_password, $glance_user_password,
   $nova_db_password, $nova_user_password, $rabbit_password, $rabbit_user,
   $rabbit_nodes, $memcached_servers, $export_resources
 ) {

    $which = $::hostname ? { $master_hostname => 0, default => 1 }

    #    $vip = $virtual_ip
    #    $hosts = $controller_hostnames
    #    $ips = $controller_internal_addresses


    # haproxy
    include haproxy::data

    Haproxy_service {
#      virtual_ip => $vip,
      hostnames => $controller_hostnames,
      balancer_ips => $controller_internal_addresses
    }

    haproxy_service { 'horizon':    order => 15, port => 80, virtual_ips => [$public_virtual_ip], define_cookies => true  } 
    haproxy_service { 'keystone-1': order => 20, port => 5000, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'keystone-2': order => 30, port => 35357, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api-1': order => 40, port => 8773, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api-2': order => 50, port => 8774, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api-3': order => 60, port => 8775, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'nova-api-4': order => 70, port => 8776, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'glance-api': order => 80, port => 9292, virtual_ips => [$public_virtual_ip, $internal_virtual_ip]  }
    haproxy_service { 'glance-reg': order => 90, port => 9191, virtual_ips => [$internal_virtual_ip]  }
    haproxy_service { 'mysqld':     order => 95, port => 3306, virtual_ips => [$internal_virtual_ip]  }

    exec { 'up-public-interface':
      command => "ifconfig ${public_interface} up",
      path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    }
    exec { 'up-internal-interface':
      command => "ifconfig ${internal_interface} up",
      path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    }
    exec { 'up-private-interface':
      command => "ifconfig ${private_interface} up",
      path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    }

    if $which == 0 { 
      exec { 'create-public-virtual-ip':
        command => "ip addr add ${public_virtual_ip} dev ${public_interface} label ${public_interface}:keepalived",
        unless => "ip addr show dev ${public_interface} | grep ${public_virtual_ip}",
        path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        before => Service['keepalived'],
        require => Exec['up-public-interface'],
      }   
    }   

    keepalived_dhcp_hook {$public_interface:interface=>$public_interface}
    keepalived_dhcp_hook {$private_interface:interface=>$internal_interface}

    Keepalived_dhcp_hook<| |> {before =>Service['keepalived']} 

    if $which == 0 { 
      exec { 'create-internal-virtual-ip':
        command => "ip addr add ${internal_virtual_ip} dev ${internal_interface} label ${internal_interface}:keepalived",
        unless => "ip addr show dev ${internal_interface} | grep ${internal_virtual_ip}",
        path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        before => Service['keepalived'],
        require => Exec['up-internal-interface'],
      }   
    }   
    sysctl::value { 'net.ipv4.ip_nonlocal_bind': value => '1' }

    $internal_address = $controller_internal_addresses[$which]

        package {'socat': ensure => present}
        exec { 'wait-for-haproxy-mysql-backend':
                command => "echo show stat | socat unix-connect:///var/lib/haproxy/stats stdio | grep 'mysqld,BACKEND' | awk -F ',' '{print \$18}' | grep -q 'UP'",
                path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
                require => [Service['haproxy'],Package['socat']],
                try_sleep   => 5,
                tries       => 6,
                }
        Exec<| title == 'wait-for-synced-state' |> -> Exec['wait-for-haproxy-mysql-backend']
        Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'initial-db-sync' |>
        Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'keystone-manage db_sync' |>
        Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'glance-manage db_sync' |>
        Exec['wait-for-haproxy-mysql-backend'] -> Exec<| title == 'nova-db-sync' |>

    class { 'haproxy':
      enable => true, 
      haproxy_global_options   => merge($::haproxy::data::haproxy_global_options, {'log' => "${internal_address} local0"}),
      haproxy_defaults_options => merge($::haproxy::data::haproxy_defaults_options, {'mode' => 'http'}),
      require => Sysctl::Value['net.ipv4.ip_nonlocal_bind'],
    }

    exec { 'create-keepalived-rules':
        command => "iptables -I INPUT -m pkttype --pkt-type multicast -d 224.0.0.18 -j ACCEPT && /etc/init.d/iptables save ", 
        unless => "iptables-save  | grep '\-A INPUT -d 224.0.0.18/32 -m pkttype --pkt-type multicast -j ACCEPT' -q",
        path => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
        before => Service['keepalived'],
        require => Class['firewall']
    }

    # keepalived
    class { 'keepalived': require => Class['haproxy'] }
    keepalived::instance { '41':
      interface => $public_interface,
      virtual_ips => [$public_virtual_ip],
      state    => $which ? { 0 => 'MASTER', default => 'BACKUP' },
      priority => $which ? { 0 => 101,      default => 100      },
    }
    keepalived::instance { '42':
      interface => $internal_interface,
      virtual_ips => [$internal_virtual_ip],
      state    => $which ? { 0 => 'MASTER', default => 'BACKUP' },
      priority => $which ? { 0 => 101,      default => 100      },
    }

#    class { 'galera':
#   require => Class['haproxy'],
#      cluster_name => 'openstack',
#      master_ip => $which ? { 0 => false, default => $controller_internal_addresses[0] },
#      node_address => $controller_internal_addresses[$which],
#    }

    class { 'firewall':
      before => Class['galera']
    }
    Class['haproxy'] -> Class['galera']
#    Class['openstack::controller']->Class['galera']
    
    class { 'openstack::controller':
      public_address          => $public_virtual_ip,
      public_interface        => $public_interface,
      private_interface       => $private_interface,
      internal_address        => $internal_virtual_ip,
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      multi_host              => $multi_host,
      network_manager         => $network_manager,
      verbose                 => $verbose,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      mysql_root_password     => $mysql_root_password,
      custom_mysql_setup_class => 'galera',
      galera_cluster_name   => 'openstack',
      galera_master_ip      => $which ? { 0 => false, default => $controller_internal_addresses[0] },
      galera_node_address   => $controller_internal_addresses[$which],
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
      cache_server_ip         => $memcached_servers,
      export_resources        => false,
      api_bind_address        => $controller_internal_addresses[$which],
      mysql_host              => $internal_virtual_ip,
      service_endpoint        => $internal_virtual_ip,
      require                 => Service['keepalived']
    }

    class { 'openstack::auth_file':
      admin_password          => $admin_password,
      keystone_admin_token    => $keystone_admin_token,
      controller_node         => $internal_virtual_ip,
    }
}

