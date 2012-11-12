  class { 'quantum': 
    rabbit_password        => '1',
    verbose                => 'True',
    debug                  => 'True',
    rabbit_host            => '172.18.66.112',
  }

  class { 'quantum::server':
    auth_password    => '1',
    auth_host        => '172.18.66.112',
    auth_tenant      => 'service',
  }

  class { 'quantum::plugins::ovs':
    sql_connection       => "mysql://root:1@172.18.66.112/ovs_quantum" ,
    tenant_network_type  => 'gre',
    enable_tunneling     => true,
  }

  class { 'quantum::agents::dhcp':
    debug            => 'True',
    use_namespaces   => 'False',
  }
  
  class { 'quantum::agents::l3':
    debug                        => 'True',
    auth_url                     => 'http://172.18.66.112:5000/v2.0',
    auth_password                => '1',
    use_namespaces               => 'False',
    metadata_ip                  => '172.18.66.112',
  }
  
  class { 'quantum::agents::ovs':
    enable_tunneling     => 'True',
    local_ip             => $::ipaddress_eth2,
  }


