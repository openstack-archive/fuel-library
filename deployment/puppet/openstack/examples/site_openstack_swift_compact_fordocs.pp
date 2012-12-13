##
# These parameters should be edit
##

# This interface will be giving away internet
$public_interface    = 'eth1'
# This interface will look to management network
$internal_interface  = 'eth0'
# This interface for internal services
$private_interface   = 'eth2'

# Public and Internal VIPs for load-balancers
$internal_virtual_ip = '10.0.0.253'
$public_virtual_ip = '10.0.2.253'
$swift_proxy_address = '10.0.0.253'

$controller_internal_addresses = {'fuel-01' => '10.0.0.101','fuel-02' => '10.0.0.102','fuel-03' => '10.0.0.103'}

# Public and Internal IP
$floating_range = '10.0.2.128/27'
$fixed_range = '10.0.198.128/27'

##
# These parameters to change by necessity
##

# Enabled or disabled different services
$cinder                  = true
$multi_host              = true
$manage_volumes          = true
$quantum                 = true
$auto_assign_floating_ip = false
$glance_backend         = 'swift'

# Set default hostname
$master_hostname = 'fuel-01'
$controller_hostnames = ['fuel-01', 'fuel-02', 'fuel-03']
$network_manager = 'nova.network.manager.FlatDHCPManager'

# Add physical volume to cinder, value must be different
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx']

# Set credential for different services
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

$swift_user_password    = 'swift_pass'
$swift_shared_secret    = 'changeme'
$quantum_user_password  = 'quantum_pass'
$quantum_db_password    = 'quantum_pass'
$quantum_db_user        = 'quantum'
$quantum_db_dbname      = 'quantum'
$tenant_network_type    = 'gre'
$quantum_sql_connection = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"

$quantum_host           = $internal_virtual_ip
$controller_node_public = $internal_virtual_ip
$swift_local_net_ip     = $ipaddress_eth1
$swift_master           = $master_hostname
$swift_proxies          = $controller_internal_addresses

# Packages version
$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
  'cinder' => latest,
}
$mirror_type="external"

$internal_address = getvar("::ipaddress_${internal_interface}")
$verbose = true
Exec { logoutput => true }

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=> $mirror_type }

if $::operatingsystem == 'Ubuntu' {
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}

class compact_controller {
  class { 'openstack::controller_ha':
    controller_public_addresses   => $controller_public_addresses,
    controller_internal_addresses => $controller_internal_addresses,
    public_interface        => $public_interface,
    internal_interface      => $internal_interface,
    private_interface       => $private_interface,
    internal_virtual_ip     => $internal_virtual_ip,
    public_virtual_ip       => $public_virtual_ip,
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
    quantum                 => $quantum,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    quantum_db_user         => $quantum_db_user,
    quantum_db_dbname       => $quantum_db_dbname,
    tenant_network_type     => $tenant_network_type,
    cinder                  => $cinder,
    manage_volumes          => $manage_volumes,
    galera_nodes            => $controller_hostnames,
    nv_physical_volume      => $nv_physical_volume,
  }

  class { 'swift::keystone::auth':
    password          => $swift_user_password,
    public_address    => $public_virtual_ip,
    internal_address  => $internal_virtual_ip,
    admin_address     => $internal_virtual_ip,
  }
}


node /fuel-01/ {
  class { compact_controller: }
  $swift_zone = 1

  class { 'openstack::swift::storage-node':
    swift_zone         => $swift_zone,
    swift_local_net_ip => $internal_address,
  }

  class { 'openstack::swift::proxy':
    swift_proxies           => $swift_proxies,
    swift_master            => $swift_master,
    controller_node_address => $internal_virtual_ip,
    swift_local_net_ip      => $internal_address,
  }
}

node /fuel-02/ {
  class { 'compact_controller': }
  $swift_zone = 2

  class { 'openstack::swift::storage-node':
    swift_zone         => $swift_zone,
    swift_local_net_ip => $internal_address,
  }

  class { 'openstack::swift::proxy':
    swift_proxies           => $swift_proxies,
    swift_master            => $swift_master,
    controller_node_address => $internal_virtual_ip,
    swift_local_net_ip      => $internal_address,
  }
}


node /fuel-03/ {
  class { 'compact_controller': }
  $swift_zone = 3

  class { 'openstack::swift::storage-node':
    swift_zone         => $swift_zone,
    swift_local_net_ip => $internal_address,
  }

  class { 'openstack::swift::proxy':
    swift_proxies           => $swift_proxies,
    swift_master            => $swift_master,
    controller_node_address => $internal_virtual_ip,
    swift_local_net_ip      => $internal_address,
  }
}


node /fuel-04/ {
    class { 'openstack::compute':
      public_interface       => $public_interface,
      private_interface      => $private_interface,
      internal_address       => $internal_address,
      libvirt_type           => 'qemu',
      fixed_range            => $fixed_range,
      network_manager        => $network_manager,
      multi_host             => $multi_host,
      sql_connection         => "mysql://nova:${nova_db_password}@${internal_virtual_ip}/nova",
      rabbit_nodes           => $controller_hostnames,
      rabbit_password        => $rabbit_password,
      rabbit_user            => $rabbit_user,
      glance_api_servers     => "${internal_virtual_ip}:9292",
      vncproxy_host          => $public_virtual_ip,
      verbose                => $verbose,
      vnc_enabled            => true,
      manage_volumes         => false,
      nova_user_password     => $nova_user_password,
      cache_server_ip        => $controller_hostnames,
      service_endpoint       => $internal_virtual_ip,
      quantum                => $quantum,
      quantum_host           => $quantum_host,
      quantum_sql_connection => $quantum_sql_connection,
      quantum_user_password  => $quantum_user_password,
      tenant_network_type    => $tenant_network_type,
      cinder                 => $cinder,
      ssh_private_key        => 'puppet:///ssh_keys/openstack',
      ssh_public_key         => 'puppet:///ssh_keys/openstack.pub',
    }
}

# deprecated. keep it for backward compatibility
$controller_public_addresses = {'fuel-01' => '10.0.2.15','fuel-02' => '10.0.2.16','fuel-03' => '10.0.2.17'}
