class zabbix::ha::haproxy inherits openstack::ha::haproxy {

  openstack::ha::haproxy_service { 'zabbix-agent':
    order               => '210',
    listen_port         => $zabbix::ports['agent'],
    balancermember_port => $zabbix::ports['backend_agent'],

    haproxy_config_options => {
      'option'         => ['tcpka'],
      'timeout client' => '48h',
      'timeout server' => '48h',
      'balance'        => 'roundrobin',
      'mode'           => 'tcp'
    },

    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }

  openstack::ha::haproxy_service { 'zabbix-server':
    order               => '200',
    listen_port         => $zabbix::ports['server'],
    balancermember_port => $zabbix::ports['backend_server'],

    haproxy_config_options => {
      'option'         => ['tcpka'],
      'timeout client' => '48h',
      'timeout server' => '48h',
      'balance'        => 'roundrobin',
      'mode'           => 'tcp'
    },

    balancermember_options => 'check inter 5000 rise 2 fall 3',
  }

  firewall { '998 zabbix agent vip':
    proto     => 'tcp',
    action    => 'accept',
    port      => $zabbix::ports['agent'],
  }

  firewall { '998 zabbix server vip':
    proto     => 'tcp',
    action    => 'accept',
    port      => $zabbix::ports['server'],
  }
}
