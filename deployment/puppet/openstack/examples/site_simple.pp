$floating_range          = '10.0.0.128/28'
$fixed_range             = '10.0.2.0/28'
$controller_hostnames    = ['fuel-01']
$controller_ip           = '10.0.0.101'
$public_interface        = 'eth1'
$internal_address        = $ipaddress_eth1
$private_interface       = 'eth2'
$multi_host              = true
$network_manager         = 'nova.network.manager.FlatDHCPManager'
$verbose                 = true
$auto_assign_floating_ip = false
$mysql_root_password     = 'nova'
$admin_email             = 'openstack@openstack.org'
$admin_password          = 'nova'
$keystone_db_password    = 'nova'
$keystone_admin_token    = 'nova'
$glance_db_password      = 'nova'
$glance_user_password    = 'nova'
$nova_db_password        = 'nova'
$nova_user_password      = 'nova'
$rabbit_password         = 'nova'
$rabbit_user             = 'nova'
$glance_backend          = 'file'
$public_address          = '10.0.0.101'
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx']
case $::osfamily {
  'RedHat': {
    $openstack_version = {
      'keystone'   => '2012.1.1-1.el6',
      'glance'     => '2012.1.1-1.el6',
      'horizon'    => '2012.1.1-1.el6',
      'nova'       => '2012.1.1-15.el6',
      'novncproxy' => '0.3-11.el6',
    }
  }
  'Debian': {
    $openstack_version = {
#     'keystone'   => '7',
#      'keystone'  => '2012.1-0ubuntu1',
#     'glance'     => '9',
#      'glance'     => '2012.1-0ubuntu2',
#     'horizon'    => '190',
#      'horizon'    => '2012.1-0ubuntu8',
#     'nova'       => '19',
#      'nova'       => '2012.1-0ubuntu2',
#     'novncproxy' => '4',
#      'novncproxy' => '2012.1~e3+dfsg+1-2',
#      'nova-common' => '2012.1-0ubuntu2',
    }
  }
}

Exec { logoutput => true }
stage {'openstack-custom-repo': before => Stage['main']}

node /fuel-01/ {
    class { 'openstack::controller': 
      public_address          => $public_address,
      internal_address        => $internal_address,
      public_interface        => $public_interface,
      private_interface       => $private_interface,
      mysql_root_password     => $mysql_root_password,
      admin_email             => $admin_email,
      admin_password          => $admin_password,
      rabbit_password         => $rabbit_password,
      rabbit_user             => $rabbit_user,
      rabbit_nodes            => $controller_hostnames,
      keystone_db_password    => $keystone_db_password,
      keystone_admin_token    => $keystone_admin_token,
      glance_db_password      => $glance_db_password,
      glance_user_password    => $glance_user_password,
      nova_db_password        => $nova_db_password,
      nova_user_password      => $nova_user_password,
      fixed_range             => $fixed_range,
      floating_range          => $floating_range,
      multi_host              => $multi_host,
      verbose                 => $verbose,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      glance_backend          => $glance_backend,
      network_manager         => $network_manager,
      export_resources        => false,
      manage_volumes          => true,
      nv_physical_volume      => $nv_physical_volume,
    }
}

node /fuel-0[234]/ {
    class { 'openstack::compute':
      public_interface   => $public_interface,
      private_interface  => $private_interface,
      internal_address   => $internal_address,
      libvirt_type       => 'qemu',
      fixed_range        => $fixed_range,
      network_manager    => $network_manager,
      multi_host         => $multi_host,
      sql_connection     => "mysql://nova:${nova_db_password}@${controller_ip}/nova",
      rabbit_nodes       => $controller_hostnames,
      rabbit_password    => $rabbit_password,
      rabbit_user        => $rabbit_user,
      glance_api_servers => "${controller_ip}:9292",
      vncproxy_host      => $public_address,
      verbose            => $verbose,
      vnc_enabled        => true,
      manage_volumes     => false,
      nova_user_password => $nova_user_password,
      cache_server_ip    => $controller_hostnames,
      service_endpoint   => "${controller_ip}",
    }
}
