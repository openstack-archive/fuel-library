$internal_virtual_ip = '10.0.0.110'
$public_virtual_ip = '10.0.0.110'
$master_hostname = 'fuel-01'
$controller_public_addresses = { 'fuel-01'=>'10.0.0.101', 'fuel-02'=>'10.0.0.102'}
$controller_internal_addresses = { 'fuel-01'=>'10.0.0.101', 'fuel-02'=>'10.0.0.102'}
$floating_range = '10.0.1.0/28'
$fixed_range = '10.0.2.0/28'
$controller_hostnames = ['fuel-01', 'fuel-02']
$public_interface = 'eth1'
$internal_interface = 'eth1'
$internal_address = getvar("::ipaddress_${internal_interface}")
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
$glance_backend         ='file'

# Disk or partition for use by nova-volume
# Each PhysicalVolume can be a disk partition, whole disk, meta device, or loopback file
$manage_volumes         = false
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx'] 

case $::osfamily {
  'RedHat': {
    $openstack_version = {
      'keystone'   => '2012.1.1-1.el6',
      'glance'     => '2012.1.1-1.el6',
      'horizon'    => '2012.1.1-1.el6',
      # set to 'latest' if you use patched packages
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
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=>$mirror_type }
if $::operatingsystem == 'Ubuntu'
{
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}
node /fuel-0[12]/ {
  if $::hostname == $master_hostname
  {
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
      internal_address        => $internal_address,
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
      galera_nodes            => $controller_hostnames,
      manage_volumes          => $manage_volumes,
      nv_physical_volume      => $nv_physical_volume,
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
      nv_physical_volume => $nv_physical_volume,
      nova_user_password => $nova_user_password,
      cache_server_ip    => $controller_hostnames,
      service_endpoint   => $internal_virtual_ip,
      ssh_private_key    => 'puppet:///ssh_keys/openstack',
      ssh_public_key     => 'puppet:///ssh_keys/openstack.pub',
    }
}

