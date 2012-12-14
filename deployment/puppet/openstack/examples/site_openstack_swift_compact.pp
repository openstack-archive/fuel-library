$internal_virtual_ip = '10.0.113.253'
$public_virtual_ip = '10.0.57.253'
$master_hostname = 'fuel-01'
$controller_public_addresses = { 'fuel-01' => '10.0.57.3', 'fuel-02' => '10.0.57.4', 'fuel-03' => '10.0.57.5' }
$controller_internal_addresses = { 'fuel-01' => '10.0.113.3', 'fuel-02' => '10.0.113.4', 'fuel-03' => '10.0.113.5' }
$swift_proxies = $controller_internal_addresses 
$floating_range = '10.0.57.128/27'
$fixed_range = '10.0.202.128/27'
$controller_hostnames = ['fuel-01', 'fuel-02', 'fuel-03']
$public_interface = 'eth2'
$internal_interface = 'eth0'
$internal_address = getvar("::ipaddress_${internal_interface}")
$private_interface = 'eth1'
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
$swift_master            = 'fuel-01'
$swift_user_password  = 'swift_pass'
# swift specific configurations
$swift_shared_secret    = 'changeme'
$swift_local_net_ip     = $internal_address
$swift_proxy_address    = '10.0.113.253'
$controller_node_public = $internal_virtual_ip
$glance_backend         = 'swift'
$manage_volumes         = false
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx']
case $::osfamily {
  'RedHat': {
    $openstack_version = {
      'keystone'   => '2012.1.1-1.el6',
      'glance'     => '2012.1.1-1.el6',
      'horizon'    => '2012.1.1-1.el6',
      'nova'       => '2012.1.1-16.mira',
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
$mirror_type="external"


Exec { logoutput => true }
stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=> $mirror_type }
if $::operatingsystem == 'Ubuntu'
{
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}
class compact_controller {
  if $::fqdn == $master_hostname {
    $manage_volumes = true
  }
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
      glance_backend          => $glance_backend,
      swift_proxies           => $swift_proxies,
      manage_volumes          => $manage_volumes, 
      galera_nodes            => $controller_hostnames,
      nv_physical_volume      => $nv_physical_volume,
      }
      class { 'swift::keystone::auth':
             password => $swift_user_password,
             public_address  => $public_virtual_ip,
             internal_address  => $internal_virtual_ip,
             admin_address  => $internal_virtual_ip,
      }

}


node /fuel-01/ {
  include compact_controller
  include swift_base
  $swift_zone = 1
  include role_swift_storage
  include role_swift_proxy
}

node /fuel-02/ {
  include compact_controller
  include swift_base
  $swift_zone = 2
  include role_swift_storage
  include role_swift_proxy
}

node /fuel-03/ {
  include compact_controller
  include swift_base
  $swift_zone = 3
  include role_swift_storage
  include role_swift_proxy
}

node /fuel-0[45]/ {
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
      ssh_private_key    => 'puppet:///ssh_keys/openstack',
      ssh_public_key     => 'puppet:///ssh_keys/openstack.pub',
    }
}
class role_swift_storage {


  # create xfs partitions on a loopback device and mount them
  swift::storage::loopback { ['dev1', 'dev2']:
    base_dir     => '/srv/loopback-device',
    mnt_base_dir => '/srv/node',
    seek         => '1048756',
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

class swift_base {
  class { 'ssh::server::install': }

  class { 'swift':
    # not sure how I want to deal with this shared secret
    swift_hash_suffix => 'swift_shared_secret',
    package_ensure    => latest,
  }
 
  class { 'rsync::server':
    use_xinetd => true,
    address    => $swift_local_net_ip,
    use_chroot => 'no',
  }

}

class role_swift_proxy {

  # curl is only required so that I can run tests
  #  package { 'curl': ensure => present }

  #class { 'memcached':
  #  listen_ip => '127.0.0.1',
  #}

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
#    require            => Class['swift::ringbuilder'],
  }

  # configure all of the middlewares
  class { [
    'swift::proxy::catch_errors',
    'swift::proxy::healthcheck',
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
   $cache_addresses =  inline_template("<%= @swift_proxies.keys.uniq.sort.collect {|ip| ip + ':11211' }.join ',' %>")
   class { 'swift::proxy::cache':
        memcache_servers => split($cache_addresses,',')
        }
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


  if $::fqdn == $swift_master {
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
  Class['swift::ringbuilder'] -> Class['swift::proxy']

  # sets up an rsync db that can be used to sync the ring DB
  
  class { 'swift::ringserver':
    local_net_ip => $swift_local_net_ip,
  }
    # exports rsync gets that can be used to sync the ring files
    @@swift::ringsync { ['account', 'object', 'container']:
      ring_server => $swift_local_net_ip
    }
  }
  else {
    Package["swift"] -> Class["swift::proxy"] 
    Swift::Ringsync<<||>>
    Swift::Ringsync<| |> ~> Service["swift-proxy"]
  }

  # deploy a script that can be used for testing
  file { '/tmp/swift_keystone_test.rb':
    source => 'puppet:///modules/swift/swift_keystone_test.rb'
  }
}




