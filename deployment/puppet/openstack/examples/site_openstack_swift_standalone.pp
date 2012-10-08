$internal_virtual_ip = '10.0.0.110'
$public_virtual_ip = '10.0.0.110'
$master_hostname = 'fuel-01'
$controller_public_addresses = ['10.0.0.101', '10.0.0.102']
$controller_internal_addresses = ['10.0.0.101', '10.0.0.102']
$floating_range = '10.0.1.0/28'
$fixed_range = '10.0.2.0/28'
$controller_hostnames = ['fuel-01', 'fuel-02']
$public_interface = 'eth1'
$internal_interface = 'eth1'
$internal_address = $ipaddress_eth1
$private_interface = 'eth2'
$multi_host = true
$network_manager = 'nova.network.manager.FlatDHCPManager'
$verbose = true
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
$swift_user_password  = 'swift_pass'
# swift specific configurations
$swift_shared_secret  = 'changeme'
$swift_local_net_ip   = $ipaddress_eth0
$swift_proxy_address    = '192.168.1.16'
$controller_node_public = $internal_virtual_ip 
$glance_backend         = 'swift'
$openstack_version = {
  'keystone'   => '2012.1.1-1.el6',
  'glance'     => '2012.1.1-1.el6',
  'horizon'    => '2012.1.1-1.el6',
  'nova'       => '2012.1.1-15.el6',
  'novncproxy' => '0.3-11.el6',
}

Exec { logoutput => true }
stage {'openstack-custom-repo': before => Stage['main']}
include openstack::mirantis_repos

node /fuel-0[12]/ {
    class { 'openstack::controller_ha': 
      controller_public_addresses => $controller_public_addresses,
      public_interface        => $public_interface,
      internal_interface      => $internal_interface,
      private_interface       => $private_interface,
      internal_virtual_ip     => $internal_virtual_ip,
      public_virtual_ip       => $public_virtual_ip,
      controller_internal_addresses => $controller_internal_addresses,
      master_hostname         => $master_hostname,
      floating_range          => $floating_range,
      fixed_range             => $fixed_range,
      multi_host              => $multi_host,
      network_manager         => $network_manager,
      verbose                 => $verbose,
      auto_assign_floating_ip => $auto_assign_floating_ip,
      mysql_root_password     => $mysql_root_password,
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
      rabbit_nodes            => $controller_hostnames,
      memcached_servers       => $controller_hostnames,
      export_resources        => false,
      glance_backend          => $glance_backend
      }
      class { 'swift::keystone::auth':
             password => $swift_user_password,
             address  => $swift_proxy_address,
      }
}

node /fuel-0[34]/ {
    class { 'openstack::compute':
      public_interface   => $public_interface,
      private_interface  => $private_interface,
      internal_address   => $internal_address,
      libvirt_type       => 'qemu',
      fixed_range        => $fixed_range,
      network_manager    => $network_manager,
      multi_host         => $multi_host,
      sql_connection     => "mysql://nova:${nova_db_password}@${internal_virtual_ip}/nova",
      rabbit_nodes       => $controller_hostnames,
      rabbit_password    => $rabbit_password,
      rabbit_user        => $rabbit_user,
      glance_api_servers => "${internal_virtual_ip}:9292",
      vncproxy_host      => $public_virtual_ip,
      verbose            => $verbose,
      vnc_enabled        => true,
      manage_volumes     => false,
      nova_user_password	=> $nova_user_password,
      cache_server_ip         => $controller_hostnames,
      service_endpoint	=> $internal_virtual_ip,
    }
}
node swift_base  {

  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => 'swift_shared_secret',
    package_ensure    => latest,
  }

}
node /fuel-05/ inherits swift_base {

  $swift_zone = 1
  include role_swift_storage

}
node /fuel-06/ inherits swift_base {

  $swift_zone = 2
  include role_swift_storage

}
node /fuel-07/ inherits swift_base {

  $swift_zone = 3
  include role_swift_storage

}
class role_swift_storage {

  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { ['dev1', 'dev2']:
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    require      => Class['swift'],
  }

  # install all swift storage servers together
  class { 'swift::storage::all':
    storage_local_net_ip => $swift_local_net_ip,
    swift_zone => $swift_zone,
  }

  # collect resources for synchronizing the ring databases
  Swift::Ringsync<<||>>

}

node /fuel-08/ inherits swift_base {

  # curl is only required so that I can run tests
  package { 'curl': ensure => present }

  class { 'memcached':
    listen_ip => '127.0.0.1',
  }

  # specify swift proxy and all of its middlewares
  class { 'swift::proxy':
    proxy_local_net_ip => $swift_local_net_ip,
    pipeline           => [
      'catch_errors',
      'healthcheck',
      'cache',
      'ratelimit',
      'swift3',
#      's3token',
      'authtoken',
      'keystone',
      'proxy-server'
    ],
    account_autocreate => true,
    # TODO where is the  ringbuilder class?
    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    'swift::proxy::catch_errors',
    'swift::proxy::healthcheck',
    'swift::proxy::cache',
    'swift::proxy::swift3',
  ]: }
  class { 'swift::proxy::ratelimit':
    clock_accuracy         => 1000,
    max_sleep_time_seconds => 60,
    log_sleep_time_seconds => 0,
    rate_buffer_seconds    => 5,
    account_ratelimit      => 0
  }
#  class { 'swift::proxy::s3token':
    # assume that the controller host is the swift api server
#    auth_host     => $controller_node_public,
#    auth_port     => '35357',
#  }
  class { 'swift::proxy::keystone':
    operator_roles => ['admin', 'SwiftOperator'],
  }
  class { 'swift::proxy::authtoken':
    admin_user        => $admin_user,
    admin_tenant_name => 'openstack',
    admin_password    => $admin_password,
    # assume that the controller host is the swift api server
    auth_host         => $controller_node_public,
  }

  # collect all of the resources that are needed
  # to balance the ring
  Ring_object_device <<| |>>
  Ring_container_device <<| |>>
  Ring_account_device <<| |>>

  # create the ring
  class { 'swift::ringbuilder':
    # the part power should be determined by assuming 100 partitions per drive
    part_power     => '18',
    replicas       => '3',
    min_part_hours => 1,
    require        => Class['swift'],
  }

  # sets up an rsync db that can be used to sync the ring DB
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }

  # exports rsync gets that can be used to sync the ring files
  @@swift::ringsync { ['account', 'object', 'container']:
   ring_server => $swift_local_net_ip
 }

  # deploy a script that can be used for testing
  file { '/tmp/swift_keystone_test.rb':
    source => 'puppet:///modules/swift/swift_keystone_test.rb'
  }
}




