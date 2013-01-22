#
# Parameter values in this file should be changed, taking into consideration your
# networking setup and desired OpenStack settings.
#
# Please consult with the latest Fuel User Guide before making edits.
#

# This is a name of public interface. Public network provides address space for Floating IPs, as well as public IP accessibility to the API endpoints.
$public_interface    = 'eth1'

# This is a name of internal interface. It will be hooked to the management network, where data exchange between components of the OpenStack cluster will happen.
$internal_interface  = 'eth0'

# This is a name of private interface. All traffic within OpenStack tenants' networks will go through this interface.
$private_interface   = 'eth2'

# Public and Internal VIPs. These virtual addresses are required by HA topology and will be managed by keepalived.
$internal_virtual_ip = '10.0.0.253'
$public_virtual_ip   = '10.0.2.253'

# Map of controller IP addresses on internal interfaces. Must have an entry for every controller node.
$controller_internal_addresses = {'fuel-controller-01' => '10.0.0.101','fuel-controller-02' => '10.0.0.102','fuel-controller-03' => '10.0.0.103'}

# Specify pools for Floating IP and Fixed IP.
# Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
# Fixed IP addresses are typically used for communication between VM instances.
$create_networks = true
$floating_range  = '10.0.2.128/27'
$fixed_range     = '10.0.198.128/27'

# These options are specific to the nova network
# and will be ignored if Quantum is enabled
$num_networks    = 1
$network_size    = 31
$vlan_start      = 300

# If $external_ipinfo option is not defined the addresses will be calculated automatically from $floating_range:
# the first address will be defined as an external default router
# second address will be set to an uplink bridge interface (br-ex)
# remaining addresses are utilized for ip floating pool
$external_ipinfo = {}
## $external_ipinfo = {
##   'public_net_router' => '10.0.2.129',
##   'ext_bridge'        => '10.0.2.130',
##   'pool_start'        => '10.0.2.131',
##   'pool_end'          => '10.0.2.158',
## }

# For VLAN networks: valid VLAN VIDs are 1 through 4094.
# For GRE networks: Valid tunnel IDs are any 32 bit unsigned integer.
$segment_range   = '900:999'

# it should be set to an integer value (valid range is 0..254)
$deployment_id = '69'

# Here you can enable or disable different services, based on the chosen deployment topology.
$cinder                  = true
$multi_host              = true
$manage_volumes          = true
$quantum                 = true
$auto_assign_floating_ip = false
$glance_backend          = 'swift'

# Use loopback device for swift
# set 'loopback' or false
$swift_loopback = 'loopback'

# Set master hostname for the HA cluster of controller nodes, as well as hostnames for every controller in the cluster.
$master_hostname      = 'fuel-controller-01'
$controller_hostnames = ['fuel-controller-01', 'fuel-controller-02', 'fuel-controller-03']

# Set up OpenStack network manager
$network_manager      = 'nova.network.manager.FlatDHCPManager'

# Setup network interface, which Cinder used for export iSCSI targets.
$cinder_iscsi_bind_iface = $internal_interface

# Here you can add physical volumes to cinder. Please replace values with the actual names of devices.
$nv_physical_volume   = ['/dev/sdz', '/dev/sdy', '/dev/sdx']

# Specify credentials for different services
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

$swift_user_password     = 'swift_pass'
$swift_shared_secret     = 'changeme'

$quantum_user_password   = 'quantum_pass'
$quantum_db_password     = 'quantum_pass'
$quantum_db_user         = 'quantum'
$quantum_db_dbname       = 'quantum'
$tenant_network_type     = 'gre'
$quantum_host            = $internal_virtual_ip

$use_syslog = false
if $use_syslog {
class { "::rsyslog::client": 
    log_local => true,
    log_auth_local => true,
    server => '127.0.0.1',
    port => '514'
 }
}
# OpenStack packages to be installed
$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
  'cinder'     => 'latest',
}

$mirror_type = 'external'

$internal_address = getvar("::ipaddress_${internal_interface}")
$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"

$controller_node_public  = $internal_virtual_ip
$swift_local_net_ip      = $internal_address
$swift_master            = $master_hostname
$swift_proxies           = $controller_internal_addresses
$verbose = true

Exec { logoutput => true }

# Globally apply an environment-based tag to all resources on each node.
tag("${::deployment_id}::${::environment}")

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=> $mirror_type }

if $::operatingsystem == 'Ubuntu' {
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}

#Rate Limits for cinder and Nova
#Cinder and Nova can rate-limit your requests to API services
#These limits can be small for your installation or usage scenario
#Change the following variables if you want. The unit is requests per minute.

$nova_rate_limits = { 'POST' => 1000,
 'POST_SERVERS' => 1000,
 'PUT' => 1000, 'GET' => 1000,
 'DELETE' => 1000 }


$cinder_rate_limits = { 'POST' => 1000,
 'POST_SERVERS' => 1000,
 'PUT' => 1000, 'GET' => 1000,
 'DELETE' => 1000 }

sysctl::value { 'net.ipv4.conf.all.rp_filter': value => '0' }

class compact_controller {
  class { 'openstack::controller_ha':
    controller_public_addresses   => $controller_public_addresses,
    controller_internal_addresses => $controller_internal_addresses,
    internal_address        => $internal_address,
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
    num_networks            => $num_networks,
    network_size            => $network_size,
    network_config          => { 'vlan_start' => $vlan_start },
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
    segment_range           => $segment_range,
    cinder                  => $cinder,
    cinder_iscsi_bind_iface => $cinder_iscsi_bind_iface,
    manage_volumes          => $manage_volumes,
    galera_nodes            => $controller_hostnames,
    nv_physical_volume      => $nv_physical_volume,
    use_syslog              => $use_syslog,
    nova_rate_limits => $nova_rate_limits,
    cinder_rate_limits => $cinder_rate_limits
  }

  class { 'swift::keystone::auth':
    password          => $swift_user_password,
    public_address    => $public_virtual_ip,
    internal_address  => $internal_virtual_ip,
    admin_address     => $internal_virtual_ip,
  }
}


# Definition of the first OpenStack controller.
node /fuel-controller-01/ {
  class { compact_controller: }
  $swift_zone = 1

  class { 'openstack::swift::storage-node':
    storage_type       => $swift_loopback,
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


# Definition of the second OpenStack controller.
node /fuel-controller-02/ {
  class { 'compact_controller': }
  $swift_zone = 2

  class { 'openstack::swift::storage-node':
    storage_type       => $swift_loopback,
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


# Definition of the third OpenStack controller.
node /fuel-controller-03/ {
  class { 'compact_controller': }
  $swift_zone = 3

  class { 'openstack::swift::storage-node':
    storage_type       => $swift_loopback,
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


# Definition of OpenStack compute node.
node /fuel-compute-[\d+]/ {
    class { 'openstack::compute':
      public_interface       => $public_interface,
      private_interface      => $private_interface,
      internal_address       => $internal_address,
      libvirt_type           => 'qemu',
      fixed_range            => $fixed_range,
      network_manager        => $network_manager,
      network_config         => { 'vlan_start' => $vlan_start },
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
      segment_range          => $segment_range,
      ssh_private_key        => 'puppet:///ssh_keys/openstack',
      ssh_public_key         => 'puppet:///ssh_keys/openstack.pub',
      use_syslog              => $use_syslog,
      nova_rate_limits => $nova_rate_limits,
      cinder_rate_limits => $cinder_rate_limits
    }
}


# Definition of OpenStack Quantum node.
node /fuel-quantum/ {
    class { 'openstack::quantum_router':
      db_host               => $internal_virtual_ip,
      service_endpoint      => $internal_virtual_ip,
      auth_host             => $internal_virtual_ip,
      internal_address      => $internal_address,
      public_interface      => $public_interface,
      private_interface     => $private_interface,
      floating_range        => $floating_range,
      fixed_range           => $fixed_range,
      create_networks       => $create_networks,
      verbose               => $verbose,
      rabbit_password       => $rabbit_password,
      rabbit_user           => $rabbit_user,
      rabbit_nodes          => $controller_hostnames,
      quantum               => $quantum,
      quantum_user_password => $quantum_user_password,
      quantum_db_password   => $quantum_db_password,
      quantum_db_user       => $quantum_db_user,
      quantum_db_dbname     => $quantum_db_dbname,
      tenant_network_type   => $tenant_network_type,
      segment_range         => $segment_range,
      external_ipinfo       => $external_ipinfo,
      api_bind_address      => $internal_address,
      use_syslog              => $use_syslog,
    }

    class { 'openstack::auth_file':
      admin_password       => $admin_password,
      keystone_admin_token => $keystone_admin_token,
      controller_node      => $internal_virtual_ip,
      before               => Class['openstack::quantum_router'],
    }
}

# This configuration option is deprecated and will be removed in future releases. It's currently kept for backward compatibility.
$controller_public_addresses = {'fuel-controller-01' => '10.0.2.15','fuel-controller-02' => '10.0.2.16','fuel-controller-03' => '10.0.2.17'}

