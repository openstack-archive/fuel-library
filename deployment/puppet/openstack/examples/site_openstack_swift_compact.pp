#
# Parameter values in this file should be changed, taking into consideration your
# networking setup and desired OpenStack settings.
# 
# Please consult with the latest Fuel User Guide before making edits.
#

### GENERAL CONFIG ###
# This section sets main parameters such as hostnames and IP addresses of different nodes

# This is the name of the public interface. The public network provides address space for Floating IPs, as well as public IP accessibility to the API endpoints.
$public_interface    = 'eth1'

# This is the name of the internal interface. It will be attached to the management network, where data exchange between components of the OpenStack cluster will happen.
$internal_interface  = 'eth0'

# This is the name of the private interface. All traffic within OpenStack tenants' networks will go through this interface.
$private_interface   = 'eth2'

# Public and Internal VIPs. These virtual addresses are required by HA topology and will be managed by keepalived.
$internal_virtual_ip = '10.0.0.253'
# Change this IP to IP routable from your 'public' network,
# e. g. Internet or your office LAN, in which your public 
# interface resides
$public_virtual_ip   = '10.0.215.253'

# Array containing key/value pairs of controllers and IP addresses for their internal interfaces. Must have an entry for every controller node.
# Fully Qualified domain names are allowed here along with short hostnames.
$controller_internal_addresses = {'fuel-controller-01' => '10.0.0.103','fuel-controller-02' => '10.0.0.104','fuel-controller-03' => '10.0.0.105'}

# Set internal address on which services should listen.
# We assume that this IP will is equal to one of the haproxy 
# backends. If the IP address does not match, this may break your environment.
# Leave internal_adderss unchanged unless you know what you are doing.
$internal_address = getvar("::ipaddress_${internal_interface}")

# Set hostname for master controller of HA cluster. 
# It is strongly recommend that the master controller is deployed before all other controllers since it initializes the new cluster.  
# Default is fuel-controller-01. 
# Fully qualified domain name is also allowed.
$master_hostname = 'fuel-controller-01'

# Array of controller hostnames. 
# Duplicating all hostnames/ip addresses, etc, seems kind of repetitive. Used by some services. MUST include the same hostnames as $controller_internal_addresses keys.
# Only short controller names allowed. Fully qualified domain names are restricted, since it breaks RabbitMQ installation and other services, 
# requiring only short names for proper work. By default this list repeats controller names from $controller_internal_addresses, but in short hostname only form.
$controller_hostnames = ['fuel-controller-01', 'fuel-controller-02', 'fuel-controller-03']

#Specify if your installation contains multiple Nova controllers. Defaults to true as it is the most common scenario.
$multi_host              = true

# Specify different DB credentials for various services
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

# End DB credentials section

### GENERAL CONFIG END ###

### NETWORK/QUANTUM ###
# Specify network/quantum specific settings

# Should we use quantum or nova-network(deprecated).
# Consult OpenStack documentation for differences between them.
$quantum                 = true

# Specify network creation criteria:
# Should puppet automatically create networks?
$create_networks = true
# Fixed IP addresses are typically used for communication between VM instances.
$fixed_range     = '10.0.198.128/27'
# Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
$floating_range  = '10.0.74.128/28'

# These parameters are passed to the previously specified network manager , e.g. nova-manage network create.
# Not used in Quantum.
# Consult openstack docs for corresponding network manager. 
# https://fuel-dev.mirantis.com/docs/0.2/pages/0050-installation-instructions.html#network-setup
$num_networks    = 1
$network_size    = 31
$vlan_start      = 300

# Quantum

# Segmentation type for isolating traffic between tenants
# Consult Openstack Quantum docs 
$tenant_network_type     = 'gre'

#Which IP to use to communicate with Quantum server?
$quantum_host            = $internal_virtual_ip

# If $external_ipinfo option is not defined, the addresses will be allocated automatically from $floating_range:
# the first address will be defined as an external default router,
# the second address will be attached to an uplink bridge interface,
# the remaining addresses will be utilized for the floating IP address pool.
$external_ipinfo = {}
## $external_ipinfo = {
##   'public_net_router' => '10.0.74.129',
##   'ext_bridge'        => '10.0.74.130',
##   'pool_start'        => '10.0.74.131',
##   'pool_end'          => '10.0.74.142',
## }

# Quantum segmentation range.
# For VLAN networks: valid VLAN VIDs can be 1 through 4094.
# For GRE networks: Valid tunnel IDs can be any 32-bit unsigned integer.
$segment_range   = '900:999'

# Set up OpenStack network manager. It is used ONLY in nova-network.
# Consult Openstack nova-network docs for possible values.
$network_manager = 'nova.network.manager.FlatDHCPManager'

# Assign floating IPs to VMs on startup automatically?
$auto_assign_floating_ip = false

# Database connection for Quantum configuration (quantum.conf)
$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${quantum_host}/${quantum_db_dbname}"

### NETWORK/QUANTUM END ###


# This parameter specifies the the identifier of the current cluster. This is needed in case of multiple environments.
# installation. Each cluster requires a unique integer value. 
# Valid identifier range is 0 to 254
$deployment_id = '79'

# Below you can enable or disable various services based on the chosen deployment topology:
### CINDER/VOLUME ###

# Should we use cinder or nova-volume(obsolete)
# Consult openstack docs for differences between them
$cinder                  = true

# Should we install cinder on compute nodes?
$cinder_on_computes      = false

#Set it to true if your want cinder-volume been installed to the host
#Otherwise it will install api and scheduler services
$manage_volumes          = true

# Setup network interface, which Cinder uses to export iSCSI targets.
# This interface defines which IP to use to listen on iscsi port for
# incoming connections of initiators
$cinder_iscsi_bind_iface = $internal_interface

# Below you can add physical volumes to cinder. Please replace values with the actual names of devices.
# This parameter defines which partitions to aggregate into cinder-volumes or nova-volumes LVM VG
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# USE EXTREME CAUTION WITH THIS SETTING! IF THIS PARAMETER IS DEFINED, 
# IT WILL AGGREGATE THE VOLUMES INTO AN LVM VOLUME GROUP
# AND ALL THE DATA THAT RESIDES ON THESE VOLUMES WILL BE LOST!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Leave this parameter empty if you want to create [cinder|nova]-volumes VG by yourself
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx'] 


### CINDER/VOLUME END ###

### GLANCE and SWIFT ###

# Which backend to use for glance
# Supported backends are "swift" and "file"
$glance_backend          = 'swift'

# Use loopback device for swift:
# set 'loopback' or false
# This parameter controls where swift partiotions are located: 
# on physical partitions or inside loopback devices.
$swift_loopback = 'loopback'

# Which IP address to bind swift components to: e.g., which IP swift-proxy should listen on
$swift_local_net_ip      = $internal_address

# IP node of controller used during swift installation
# and put into swift configs
$controller_node_public  = $internal_virtual_ip

# Set hostname of swift_master.
# It tells on which swift proxy node to build 
# *ring.gz files. Other swift proxies/storages
# will rsync them. 
# Short hostnames allowed only. No FQDNs.
$swift_master            = $master_hostname

# Hash of proxies hostname|fqdn => ip mappings.
# This is used by controller_ha.pp manifests for haproxy setup
# of swift_proxy backends
$swift_proxies           = $controller_internal_addresses

### Glance and swift END ###

### Syslog ###
# Enable error messages reporting to rsyslog. Rsyslog must be installed in this case.
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
#
# OpenStack packages and customized component versions to be installed. 
# Use 'latest' to get the most rescent ones or specify exact version if you need to install custom version.
$openstack_version = {
  'keystone'         => 'latest',
  'glance'           => 'latest',
  'horizon'          => 'latest',
  'nova'             => 'latest',
  'novncproxy'       => 'latest',
  'cinder'           => 'latest',
  'rabbitmq_version' => $rabbitmq_version_string,
}

# Which package repo mirror to use. Currently "external" is used by default.
# "internal" is used by Mirantis for testing purposes.
# Local puppet-managed repo option planned for future releases.

# If you want to set up a local repository, you will need to manually adjust mirantis_repos.pp,
# though it is NOT recommended.
$mirror_type = 'external'


# This parameter specifies the verbosity level of log messages
# in openstack components config. Currently, it disables or enables debugging.
$verbose = true

#Rate Limits for cinder and Nova
#Cinder and Nova can rate-limit your requests to API services.
#These limits can be reduced for your installation or usage scenario.
#Change the following variables if you want. They are measured in requests per minute.
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

class compact_controller (
  $quantum_is_network_node = false
) {
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
    nova_rate_limits        => $nova_rate_limits,
    cinder_rate_limits      => $cinder_rate_limits,
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
