  class { 'neutron':
    rabbit_password        => '1',
    verbose                => true,
    debug                  => true,
    rabbit_host            => '172.18.66.112',
  }

  class { 'neutron::server':
    auth_password    => '1',
    auth_host        => '172.18.66.112',
    auth_tenant      => 'service',
  }

  class { 'neutron::plugins::ovs':
    sql_connection       => "mysql://root:1@172.18.66.112/ovs_neutron" ,
    tenant_network_type  => 'gre',
    enable_tunneling     => true,
  }

  class { 'neutron::agents::dhcp':
    debug            => true,
    use_namespaces   => 'False',
  }

  class { 'neutron::agents::l3':
    debug                        => true,
    auth_url                     => 'http://172.18.66.112:5000/v2.0',
    auth_password                => '1',
    use_namespaces               => 'False',
    metadata_ip                  => '172.18.66.112',
  }

  class { 'neutron::agents::ovs':
    enable_tunneling     => 'True',
    local_ip             => $::ipaddress_eth2,
  }


