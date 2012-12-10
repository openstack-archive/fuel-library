$public_interface    = 'eth0'
$internal_interface  = 'eth1'
$private_interface   = 'eth2'
$internal_virtual_ip = '10.0.125.253'
$public_virtual_ip   = '10.0.74.253'

$controller_public_addresses = { 'fuel-01'=>'10.0.74.3', 'fuel-02'=>'10.0.74.4'}
$controller_internal_addresses = { 'fuel-01'=>'10.0.125.3', 'fuel-02'=>'10.0.125.4'}

$floating_range = '10.0.74.128/28'
$fixed_range = '10.0.161.128/28'



$multi_host              = true
$cinder                  = true
$manage_volumes          = true
$quantum                 = true
$auto_assign_floating_ip = false

# set this parameter to 'false' if you use patched packages
$apply_highavail_patches = false

$master_hostname         = 'fuel-01'
$controller_hostnames    = ['fuel-01', 'fuel-02']
$glance_backend          ='file'
$nv_physical_volume      = ['/dev/sdz', '/dev/sdy', '/dev/sdx'] 
$network_manager         = 'nova.network.manager.FlatDHCPManager'
$mirror_type="external"

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

$quantum_user_password  = 'quantum_pass'
$quantum_db_password    = 'quantum_pass'
$quantum_db_user        = 'quantum'
$quantum_db_dbname      = 'quantum'
$tenant_network_type    = 'gre'

$openstack_version = {
  'keystone'   => latest,
  'glance'     => latest,
  'horizon'    => latest,
  'nova'       => latest,
  'novncproxy' => latest,
  'cinder' => latest,
}

$internal_address = getvar("::ipaddress_${internal_interface}")
Exec { logoutput => true }

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=>$mirror_type }
if $::operatingsystem == 'Ubuntu'
{
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}


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
      glance_backend          => $glance_backend,
      quantum                 => $quantum,
      quantum_user_password   => $quantum_user_password,
      quantum_db_password     => $quantum_db_password,
      quantum_db_user         => $quantum_db_user,
      quantum_db_dbname       => $quantum_db_dbname,
      tenant_network_type     => $tenant_network_type,
      cinder                  => $cinder,
      galera_nodes            => $controller_hostnames,
      manage_volumes          => $manage_volumes,
      nv_physical_volume      => $nv_physical_volume,
      patch_apply             => $apply_highavail_patches,
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
      nova_user_password	=> $nova_user_password,
      cache_server_ip         => $controller_hostnames,
      service_endpoint	 => $internal_virtual_ip,
      quantum                => $quantum,
      quantum_host           => $quantum_host,
      quantum_sql_connection => $quantum_sql_connection,
      quantum_user_password  => $quantum_user_password,
      tenant_network_type     => $tenant_network_type,
      cinder                  => $cinder,
      ssh_private_key    => 'puppet:///ssh_keys/openstack',
      ssh_public_key     => 'puppet:///ssh_keys/openstack.pub',
      patch_apply        => $apply_highavail_patches,
    }
}

