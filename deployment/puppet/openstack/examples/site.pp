# 2 networks:
#  - 192.168.56.0/24 on eth1 - internal network
#  - 10.0.0.0/24     on eth2 - VM network
# Controller also has another (external) network 192.168.111.1

node /controller-1/ {
	class { 'galera' : cluster_name => 'openstack' }
}
node /compute-[12]/ {
	class { 'galera' : cluster_name => 'openstack', master_ip => 'controller-1' }
}

/*
node /controller-1/ {
    class { 'openstack::controller':
      public_address          => '192.168.111.1',
      public_interface        => 'eth1',
      private_interface       => 'eth2',
      internal_address        => '192.168.56.200',
      floating_range          => '192.168.111.100/28',
      fixed_range             => '10.0.0.0/24',
      multi_host              => false,
      network_manager         => 'nova.network.manager.FlatDHCPManager',
      verbose                 => true,
      auto_assign_floating_ip => false,
      mysql_root_password     => 'nova',
      admin_email             => 'openstack@openstack.org',
      admin_password          => 'nova',
      keystone_db_password    => 'nova',
      keystone_admin_token    => 'nova',
      glance_db_password      => 'nova',
      glance_user_password    => 'nova',
      nova_db_password        => 'nova',
      nova_user_password      => 'nova',
      rabbit_password         => 'nova',
      rabbit_user             => 'nova',
      export_resources        => false,
    }

    class { 'openstack::auth_file':
      admin_password          => 'nova',
      keystone_admin_token    => 'nova',
      controller_node         => '192.168.56.200'
    }
}

node /compute-[12]/ {
    class { 'openstack::compute':
      public_interface   => 'eth1',
      private_interface  => 'eth2',
      internal_address   => $ipaddress_eth1,
      libvirt_type       => 'qemu',
      fixed_range        => '10.0.0.0/24',
      network_manager    => 'nova.network.manager.FlatDHCPManager',
      multi_host         => false,
      sql_connection     => 'mysql://nova:nova@192.168.56.200/nova',
      rabbit_host        => '192.168.56.200',
      rabbit_password    => 'nova',
      rabbit_user        => 'nova',
      glance_api_servers => '192.168.56.200:9292',
      vncproxy_host      => '192.168.56.200',
      verbose            => true,
      vnc_enabled        => true,
      manage_volumes     => false,
    }
}
*/
