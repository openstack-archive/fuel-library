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

# Specify pools for Floating IP and Fixed IP.
# Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
# Fixed IP addresses are typically used for communication between VM instances.
$floating_range  = '10.0.74.128/28'
$fixed_range     = '10.0.214.0/24'
$num_networks    = 1
$network_size    = 255
$vlan_start      = 300

# Here you can enable or disable different services, based on the chosen deployment topology.
$cinder                  = true
$multi_host              = true
$manage_volumes          = true
$quantum                 = false
$auto_assign_floating_ip = false

# Addresses of controller node
$controller_node_address = '10.0.125.3'
$controller_node_public  = '10.0.74.3'

# Set up OpenStack network manager
$network_manager      = 'nova.network.manager.FlatDHCPManager'

# Setup network interface, which Cinder used for export iSCSI targets.
$cinder_iscsi_bind_iface = $internal_interface

# Here you can add physical volumes to cinder. Please replace values with the actual names of devices.
$nv_physical_volume   = ['/dev/sdz', '/dev/sdy', '/dev/sdx']

# Specify credentials for different services
$admin_email             = 'root@localhost'
$admin_password          = 'keystone_admin'

$keystone_db_password    = 'keystone_db_pass'
$keystone_admin_token    = 'keystone_admin_token'

$nova_db_password        = 'nova_pass'
$nova_user_password      = 'nova_pass'

$glance_db_password      = 'glance_pass'
$glance_user_password    = 'glance_pass'

$rabbit_password         = 'openstack_rabbit_password'
$rabbit_user             = 'openstack_rabbit_user'

$quantum_user_password   = 'quantum_pass'
$quantum_db_password     = 'quantum_pass'
$quantum_db_user         = 'quantum'
$quantum_db_dbname       = 'quantum'
$tenant_network_type     = 'gre'

$controller_node_internal = $controller_node_address
$quantum_host             = $controller_node_address
$sql_connection           = "mysql://nova:${nova_db_password}@${controller_node_internal}/nova"
$quantum_sql_connection   = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"



$use_syslog = false
if $use_syslog {
class { "::rsyslog::client": 
    log_local => true,
    log_auth_local => true,
    server => '127.0.0.1',
    port => '514'
 }
}
  case $::osfamily {
    "Debian":  {
       $rabbitmq_version_string = '2.7.1-0ubuntu4'
    }
    "RedHat": {
       $rabbitmq_version_string = '2.8.7-2.el6'
    }
  }
# OpenStack packages to be installed
$openstack_version = {
  'keystone'         => 'latest',
  'glance'           => 'latest',
  'horizon'          => 'latest',
  'nova'             => 'latest',
  'novncproxy'       => 'latest',
  'cinder'           => 'latest',
  'rabbitmq_version' => $rabbitmq_version_string,
}

$mirror_type = 'external'

$verbose = true
Exec { logoutput => true }

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type => $mirror_type }

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

# Definition of OpenStack controller node.
node /fuel-controller-[\d+]/ {

  class { 'openstack::controller':
    admin_address           => $controller_node_internal,
    public_address          => $controller_node_public,
    public_interface        => $public_interface,
    private_interface       => $private_interface,
    internal_address        => $controller_node_internal,
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
    export_resources        => false,
    quantum                 => $quantum,
    quantum_user_password   => $quantum_user_password,
    quantum_db_password     => $quantum_db_password,
    quantum_db_user         => $quantum_db_user,
    quantum_db_dbname       => $quantum_db_dbname,
    tenant_network_type     => $tenant_network_type,
    cinder                  => $cinder,
    cinder_iscsi_bind_iface => $cinder_iscsi_bind_iface,
    manage_volumes          => $manage_volumes,
    nv_physical_volume      => $nv_physical_volume,
    use_syslog              => $use_syslog,
    nova_rate_limits        => $nova_rate_limits,
    cinder_rate_limits      => $cinder_rate_limits
  }

  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_node_internal,
  }
}

# Definition of OpenStack compute nodes.
node /fuel-compute-[\d+]/ {

  class { 'openstack::compute':
    public_interface       => $public_interface,
    private_interface      => $private_interface,
    internal_address       => getvar("::ipaddress_${internal_interface}"),
    libvirt_type           => 'kvm',
    fixed_range            => $fixed_range,
    network_manager        => $network_manager,
    network_config         => { 'vlan_start' => $vlan_start },
    multi_host             => $multi_host,
    sql_connection         => $sql_connection,
    nova_user_password     => $nova_user_password,
    rabbit_nodes           => [$controller_node_internal],
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    glance_api_servers     => "${controller_node_internal}:9292",
    vncproxy_host          => $controller_node_public,
    vnc_enabled            => true,
    ssh_private_key        => 'puppet:///ssh_keys/openstack',
    ssh_public_key         => 'puppet:///ssh_keys/openstack.pub',
    quantum                => $quantum,
    quantum_host           => $quantum_host,
    quantum_sql_connection => $quantum_sql_connection,
    quantum_user_password  => $quantum_user_password,
    tenant_network_type    => $tenant_network_type,
    service_endpoint       => $controller_node_internal,
    db_host                => $controller_node_internal,
    manage_volumes         => $manage_volumes,
    verbose                => $verbose,
    use_syslog             => $use_syslog,
    nova_rate_limits       => $nova_rate_limits,
    cinder_rate_limits     => $cinder_rate_limits
  }
}
