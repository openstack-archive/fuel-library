#
# Parameter values in this file should be changed, taking into consideration your
# networking setup and desired OpenStack settings.
# 
# Please consult with the latest Fuel User Guide before making edits.
#

### GENERAL CONFIG ###

# This section sets main parameters such as hostnames and IP addresses of different nodes

# This is a name of public interface. Public network provides address space for Floating IPs, as well as public IP accessibility to the API endpoints.
$public_interface    = 'eth1'

# This is a name of internal interface. It will be hooked to the management network, where data exchange between components of the OpenStack cluster will happen.
$internal_interface  = 'eth0'

# This is a name of private interface. All traffic within OpenStack tenants' networks will go through this interface.
$private_interface   = 'eth2'

# Public and Internal VIPs. These virtual addresses are required by HA topology and will be managed by keepalived.
$internal_virtual_ip = '10.0.126.253'
$public_virtual_ip   = '10.0.215.253'

# Map of controller IP addresses on internal interfaces. Must have an entry for every controller node.
$controller_internal_addresses = {'fuel-controller-01' => '10.0.126.3','fuel-controller-02' => '10.0.126.4','fuel-controller-03' => '10.0.126.5'}

# Set internal address on which services should listen.
# We assume that this IP will is equal to one of the haproxy 
# backends. If it is not equal, this may break things
# So leave it unchanged unless you know what you are doing

$internal_address = getvar("::ipaddress_${internal_interface}")

# Set master hostname for the HA cluster of controller nodes, as well as hostnames for every controller in the cluster.
$master_hostname = 'fuel-controller-01'

# Controllers hostnames array. Used by some services. MUST be equal to $controller_internal_addresses keys

$controller_hostnames = ['fuel-controller-01', 'fuel-controller-02', 'fuel-controller-03']

#Specify if your installation is single-node or not. Defaults to true as this is the most common scenario

$multi_host              = true

# Specify DB credentials for different services
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


### GENERAL CONFIG END ###

### NETWORK/QUANTUM ###
# Specify network/quantum specific settings

# Should we use quantum or nova-network(deprecated).
# Consult openstack docs for differences between them
$quantum                 = true

# Specify networks creation details.

# Should puppet manifests create networks ?
$create_networks = true
# Fixed IP addresses are typically used for communication between VM instances.
$fixed_range     = '10.0.198.128/27'
# Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
$floating_range  = '10.0.74.128/28'

# These parameters are passed to  openstack network creation utility (e.g. nova-manage network create).
# Not used in quantum.
# Consult openstack docs for corresponding network manager.

$num_networks    = 1
$network_size    = 31
$vlan_start      = 300

# Quantum

# Segmentation type for isolating traffic between tenants
# Consult Openstack Quantum docs 

$tenant_network_type     = 'gre'

#Which IP to use to communicate with quantum ?

$quantum_host            = $internal_virtual_ip

# If $external_ipinfo option is not defined the addresses will be calculated automatically from $floating_range:
# the first address will be defined as an external default router
# second address will be set to an uplink bridge interface (br-ex)
# remaining addresses are utilized for ip floating pool

$external_ipinfo = {}
## $external_ipinfo = {
##   'public_net_router' => '10.0.74.129',
##   'ext_bridge'        => '10.0.74.130',
##   'pool_start'        => '10.0.74.131',
##   'pool_end'          => '10.0.74.142',
## }

# Quantum segmentation range.
# For VLAN networks: valid VLAN VIDs are 1 through 4094.
# For GRE networks: Valid tunnel IDs are any 32 bit unsigned integer.
$segment_range   = '900:999'

# Set up OpenStack network manager. It is used ONLY in nova-network.
# Consult Openstack nova-network docs for possible values.
$network_manager = 'nova.network.manager.FlatDHCPManager'

# Assign floating IPs to VMs on startup automatically?
$auto_assign_floating_ip = false

# Which string to put into quantum.conf

$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"

### NETWORK/QUANTUM END ###


# This parameter specifies the id of current deployment. This is needed in case of multiple environment
# instalation. Set it for unique integer value for every environment. 
# It should be set to an integer value (valid range is 0..254)
$deployment_id = '79'

# Here you can enable or disable different services, based on the chosen deployment topology.

### CINDER/VOLUME ###

# Should we use cinder or nova-volume(obsolete)
# Consult openstack docs for differences between them
$cinder                  = true

# Should we install cinder on compute nodes?
$cinder_on_computes      = $cinder

#Set it to true if your want cinder-volume been installed to the host
#Otherwise it will install api and scheduler services
$manage_volumes          = true

# Setup network interface, which Cinder used for export iSCSI targets.
# This interface defines which IP to use to listen on iscsi port for
# incoming connections of initiators

$cinder_iscsi_bind_iface = $internal_interface

# Here you can add physical volumes to cinder. Please replace values with the actual names of devices.
# This parameter defines which partitions to aggregate into cinder-volumes or nova-volumes LVM VG
# !!
# BE REALLY CAREFUL WITH THIS. IF THIS PARAMETER IS DEFINED, IT WILL AGGREGATE THE VOLUMES INTO LVM VG
# AND THE DATA THAT RESIDES ON THIS VOLUMES WILL BE LOST.
# !!
# Leave this parameter empty if you want to create [cinder|nova]-volumes VG by yourself

$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx'] 


### CINDER/VOLUME END ###

### GLANCE and SWIFT ###

# Which backend to use for glance
# Currently supported are "swift" and "file"
$glance_backend          = 'swift'

# Use loopback device for swift
# set 'loopback' or false
# This controls where swift partiotions
# are located: on physical partitions
# or inside loopback devices
$swift_loopback = 'loopback'

# Which ip to bind particular service during swift components
# configuration: e.g., which ip swift-proxy should listen on

$swift_local_net_ip      = $internal_address

# IP node of controller used during swift installation
# and put into swift configs

$controller_node_public  = $internal_virtual_ip

# Set fqdn of swift_master.
# It tells on which swift proxy node to build 
# *ring.gz files. Other swift proxies/storages
# will rsync them

$swift_master            = $master_hostname

# Hash of proxies hostname|fqdn => ip mappings.
# This is used by controller_ha.pp manifests for haproxy setup
# of swift_proxy backends
$swift_proxies           = $controller_internal_addresses

### Glance and swift END ###

### Syslog ###
$use_syslog = false
if $use_syslog {
class { "::rsyslog::client": 
    log_local => true,
    log_auth_local => true,
    server => '127.0.0.1',
    port => '514'
 }
}

### Syslog END ###
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

# Which package repo mirror to use. Currently "external" is used.
# "internal" is used by Mirantis for testing purposes
# Customization of internal repo is planned to be allowed in
# future releases. 

# If you want to setup it, you will need to rewrite mirantis_repos.pp,
# though it is NOT  recommended.

$mirror_type = 'external'


# This parameter specifies the verboseness of log messages
# in openstack components config. Currently, it disables or enables
# debug

$verbose = true

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


Exec { logoutput => true }

### END OF PUBLIC CONFIGURATION PART ###

# Normally, you do not need to change anything after this string 

# Globally apply an environment-based tag to all resources on each node.
tag("${::deployment_id}::${::environment}")

stage { 'openstack-custom-repo': before => Stage['main'] }
class { 'openstack::mirantis_repos': stage => 'openstack-custom-repo', type=> $mirror_type }

if $::operatingsystem == 'Ubuntu' {
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}

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
    password         => $swift_user_password,
    public_address   => $public_virtual_ip,
    internal_address => $internal_virtual_ip,
    admin_address    => $internal_virtual_ip,
  }
}

# Definition of the first OpenStack controller.
node /fuel-controller-01/ {
  class { compact_controller: }
  $swift_zone = 1

  class { 'openstack::swift::storage_node':
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

  class { 'openstack::swift::storage_node':
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

  class { 'openstack::swift::storage_node':
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

# Definition of OpenStack compute nodes.
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
    manage_volumes         => $manage_volumes,
    nova_user_password     => $nova_user_password,
    cache_server_ip        => $controller_hostnames,
    service_endpoint       => $internal_virtual_ip,
    quantum                => $quantum,
    quantum_host           => $quantum_host,
    quantum_sql_connection => $quantum_sql_connection,
    quantum_user_password  => $quantum_user_password,
    tenant_network_type    => $tenant_network_type,
    segment_range          => $segment_range,
    cinder                 => $cinder_on_computes,
    cinder_iscsi_bind_iface => $cinder_iscsi_bind_iface,
    nv_physical_volume      => $nv_physical_volume,
    db_host                => $internal_virtual_ip,
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
$controller_public_addresses = {'fuel-controller-01' => '10.0.215.3','fuel-controller-02' => '10.0.215.4','fuel-controller-03' => '10.0.215.5'}
