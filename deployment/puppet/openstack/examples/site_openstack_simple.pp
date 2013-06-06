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
$public_br           = 'br-ex'

# This is the name of the internal interface. It will be attached to the management network, where data exchange between components of the OpenStack cluster will happen.
$internal_interface  = 'eth0'
$internal_br         = 'br-mgmt'

# This is the name of the private interface. All traffic within OpenStack tenants' networks will go through this interface.
$private_interface   = 'eth2'

$nodes_harr = [
  {
    'name' => 'fuel-cobbler',
    'role' => 'cobbler',
    'internal_address' => '10.0.0.102',
    'public_address'   => '10.0.204.102',
  },
  {
    'name' => 'fuel-controller-01',
    'role' => 'controller',
    'internal_address' => '10.0.0.103',
    'public_address'   => '10.0.204.103',
  },
  {
    'name' => 'fuel-compute-01',
    'role' => 'compute',
    'internal_address' => '10.0.0.106',
    'public_address'   => '10.0.204.106',
  },
  {
    'name' => 'fuel-compute-02',
    'role' => 'compute',
    'internal_address' => '10.0.0.107',
    'public_address'   => '10.0.204.107',
  },
  {
    'name' => 'fuel-compute-03',
    'role' => 'compute',
    'internal_address' => '10.0.0.108',
    'public_address'   => '10.0.204.108',
  },
]
$nodes = $nodes_harr
$default_gateway = '10.0.204.1'

# Specify nameservers here.
# Need points to cobbler node IP, or to special prepared nameservers if you known what you do.
$dns_nameservers = ['10.0.204.1','8.8.8.8']

# Specify netmasks for internal and external networks.
$internal_netmask = '255.255.255.0'
$public_netmask = '255.255.255.0'


$node = filter_nodes($nodes,'name',$::hostname)
$internal_address = $node[0]['internal_address']
$public_address = $node[0]['public_address']

$controllers = merge_arrays(filter_nodes($nodes,'role','primary-controller'), filter_nodes($nodes,'role','controller'))
$controller_internal_address = $controllers[0]['internal_address']
$controller_public_address   = $controllers[0]['public_address']

#Set this to anything other than pacemaker if you do not want Quantum HA
#Also, if you do not want Quantum HA, you MUST enable $quantum_network_node
#on the ONLY controller
$ha_provider = 'generic'
#$use_unicast_corosync = false

# Set nagios master fqdn
$nagios_master        = 'nagios-server.localdomain'
## proj_name  name of environment nagios configuration
$proj_name            = 'test'

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
$quantum_netnode_on_cnt  = true

# Specify network creation criteria:
# Should puppet automatically create networks?
$create_networks = true
# Fixed IP addresses are typically used for communication between VM instances.
$fixed_range     = '10.0.198.128/27'
# Floating IP addresses are used for communication of VM instances with the outside world (e.g. Internet).
$floating_range  = '10.0.204.128/28'

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
$tenant_network_type     = 'vlan'

# Which IP address will be used for creating GRE tunnels.
$quantum_gre_bind_addr = $internal_address

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
$segment_range   = '300:349'

# Set up OpenStack network manager. It is used ONLY in nova-network.
# Consult Openstack nova-network docs for possible values.
$network_manager = 'nova.network.manager.FlatDHCPManager'

# Assign floating IPs to VMs on startup automatically?
$auto_assign_floating_ip = false

# Database connections
$sql_connection = "mysql://nova:${nova_db_password}@${controller_internal_address}/nova"
$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${controller_internal_address}/${quantum_db_dbname}"


if $quantum {
  $public_int   = $public_br
  $internal_int = $internal_br
} else {
  $public_int   = $public_interface 
  $internal_int = $internal_interface
}

#Network configuration
stage {'netconfig':
      before  => Stage['main'],
}

class {'l23network': use_ovs=>$quantum, stage=> 'netconfig'}
class node_netconfig (
  $mgmt_ipaddr,
  $mgmt_netmask  = '255.255.255.0',
  $public_ipaddr = undef,
  $public_netmask= '255.255.255.0',
  $save_default_gateway=false,
  $quantum = $quantum,
) {
  if $quantum {
    l23network::l3::create_br_iface {'mgmt':
      interface => $internal_interface, # !!! NO $internal_int /sv !!!
      bridge    => $internal_br,
      ipaddr    => $mgmt_ipaddr,
      netmask   => $mgmt_netmask,
      dns_nameservers      => $dns_nameservers,
      save_default_gateway => $save_default_gateway,
    } ->
    l23network::l3::create_br_iface {'ex':
      interface => $public_interface, # !! NO $public_int /sv !!!
      bridge    => $public_br,
      ipaddr    => $public_ipaddr,
      netmask   => $public_netmask,
      gateway   => $default_gateway,
    }
  } else {
    # nova-network mode
    l23network::l3::ifconfig {$public_int:
      ipaddr  => $public_ipaddr,
      netmask => $public_netmask,
      gateway => $default_gateway,
    }
    l23network::l3::ifconfig {$internal_int:
      ipaddr  => $mgmt_ipaddr,
      netmask => $mgmt_netmask,
      dns_nameservers      => $dns_nameservers,
    }
  }
  l23network::l3::ifconfig {$private_interface: ipaddr=>'none' }
}
### NETWORK/QUANTUM END ###


# This parameter specifies the the identifier of the current cluster. This is needed in case of multiple environments.
# installation. Each cluster requires a unique integer value. 
# Valid identifier range is 1 to 254
$deployment_id = '69'

# Below you can enable or disable various services based on the chosen deployment topology:
### CINDER/VOLUME ###

# Should we use cinder or nova-volume(obsolete)
# Consult openstack docs for differences between them
$cinder                  = true

# Choose which nodes to install cinder onto
# 'compute'            -> compute nodes will run cinder
# 'controller'         -> controller nodes will run cinder
# 'storage'            -> storage nodes will run cinder
# 'fuel-controller-XX' -> specify particular host(s) by hostname
# 'XXX.XXX.XXX.XXX'    -> specify particular host(s) by IP address
# 'all'                -> compute, controller, and storage nodes will run cinder (excluding swift and proxy nodes)

$cinder_nodes          = ['controller']

#Set it to true if your want cinder-volume been installed to the host
#Otherwise it will install api and scheduler services
$manage_volumes          = true

# Setup network interface, which Cinder uses to export iSCSI targets.
$cinder_iscsi_bind_addr = $internal_address

# Below you can add physical volumes to cinder. Please replace values with the actual names of devices.
# This parameter defines which partitions to aggregate into cinder-volumes or nova-volumes LVM VG
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# USE EXTREME CAUTION WITH THIS SETTING! IF THIS PARAMETER IS DEFINED, 
# IT WILL AGGREGATE THE VOLUMES INTO AN LVM VOLUME GROUP
# AND ALL THE DATA THAT RESIDES ON THESE VOLUMES WILL BE LOST!
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Leave this parameter empty if you want to create [cinder|nova]-volumes VG by yourself
$nv_physical_volume     = ['/dev/sdz', '/dev/sdy', '/dev/sdx'] 

#Evaluate cinder node selection
if ($cinder) {
  if (member($cinder_nodes,'all')) {
    $is_cinder_node = true
  } elsif (member($cinder_nodes,$::hostname)) {
    $is_cinder_node = true
  } elsif (member($cinder_nodes,$internal_address)) {
    $is_cinder_node = true
  } elsif ($node[0]['role'] =~ /controller/ ) {
    $is_cinder_node = member($cinder_nodes,'controller')
  } else {
    $is_cinder_node = member($cinder_nodes,$node[0]['role'])
  }
} else {
  $is_cinder_node = false
}

### CINDER/VOLUME END ###

### GLANCE and SWIFT ###

# Which backend to use for glance
# Supported backends are "swift" and "file"
$glance_backend = 'file'

# Use loopback device for swift:
# set 'loopback' or false
# This parameter controls where swift partitions are located:
# on physical partitions or inside loopback devices.
$swift_loopback = false

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
       $rabbitmq_version_string = '2.8.7-1'
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

# Which package repo mirror to use. Currently "default".
# "custom" is used by Mirantis for testing purposes.
# Local puppet-managed repo option planned for future releases.
# If you want to set up a local repository, you will need to manually adjust mirantis_repos.pp,
# though it is NOT recommended.
$mirror_type = 'default'
$enable_test_repo = false
$repo_proxy = undef
$use_upstream_mysql = true

# This parameter specifies the verbosity level of log messages
# in openstack components config. Currently, it disables or enables debugging.
$verbose = true

#Rate Limits for cinder and Nova
#Cinder and Nova can rate-limit your requests to API services.
#These limits can be reduced for your installation or usage scenario.
#Change the following variables if you want. They are measured in requests per minute.
$nova_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000, 'GET' => 1000,
  'DELETE' => 1000 
}
$cinder_rate_limits = {
  'POST' => 1000,
  'POST_SERVERS' => 1000,
  'PUT' => 1000, 'GET' => 1000,
  'DELETE' => 1000 
}


Exec { logoutput => true }
#Specify desired NTP servers here.
#If you leave it undef pool.ntp.org
#will be used

$ntp_servers = ['pool.ntp.org']

class {'openstack::clocksync': ntp_servers=>$ntp_servers}

#Exec clocksync from openstack::clocksync before services
#connectinq to AMQP server are started.

Exec<| title == 'clocksync' |>->Nova::Generic_service<| |>
Exec<| title == 'clocksync' |>->Service<| title == 'quantum-l3' |>
Exec<| title == 'clocksync' |>->Service<| title == 'quantum-dhcp-service' |>
Exec<| title == 'clocksync' |>->Service<| title == 'quantum-ovs-plugin-service' |>
Exec<| title == 'clocksync' |>->Service<| title == 'cinder-volume' |>
Exec<| title == 'clocksync' |>->Service<| title == 'cinder-api' |>
Exec<| title == 'clocksync' |>->Service<| title == 'cinder-scheduler' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'keystone-manage db_sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'keystone-manage pki_setup' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'glance-manage db_sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'nova-manage db sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'initial-db-sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'post-nova_config' |>




### END OF PUBLIC CONFIGURATION PART ###
# Normally, you do not need to change anything after this string 

# Globally apply an environment-based tag to all resources on each node.
tag("${::deployment_id}::${::environment}")


stage { 'openstack-custom-repo': before => Stage['netconfig'] }
class { 'openstack::mirantis_repos':
  stage => 'openstack-custom-repo',
  type=>$mirror_type,
  enable_test_repo=>$enable_test_repo,
  repo_proxy=>$repo_proxy,
  use_upstream_mysql=>$use_upstream_mysql
}
 stage {'openstack-firewall': before => Stage['main'], require => Stage['netconfig'] } 
 class { '::openstack::firewall':
      stage => 'openstack-firewall'
 }

if !defined(Class['selinux']) and ($::osfamily == 'RedHat') {
  class { 'selinux':
    mode=>"disabled",
    stage=>"openstack-custom-repo"
  }
}


if $::operatingsystem == 'Ubuntu' {
  class { 'openstack::apparmor::disable': stage => 'openstack-custom-repo' }
}

sysctl::value { 'net.ipv4.conf.all.rp_filter': value => '0' }

# Dashboard(horizon) https/ssl mode
#     false: normal mode with no encryption
# 'default': uses keys supplied with the ssl module package
#   'exist': assumes that the keys (domain name based certificate) are provisioned in advance
#  'custom': require fileserver static mount point [ssl_certs] and hostname based certificate existence
$horizon_use_ssl = false


class simple_controller (
  $quantum_network_node = true
) {
  class {'::node_netconfig':
    mgmt_ipaddr    => $::internal_address,
    mgmt_netmask   => $::internal_netmask,
    public_ipaddr  => $::public_address,
    public_netmask => $::public_netmask,
    stage          => 'netconfig',
  }
  class { 'openstack::controller':
    admin_address           => $controller_internal_address,
    service_endpoint        => $controller_internal_address,
    public_address          => $controller_public_address,
    public_interface        => $public_int,
    private_interface       => $private_interface,
    internal_address        => $controller_internal_address,
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
    quantum_network_node    => $quantum_network_node,
    quantum_netnode_on_cnt  => $quantum_netnode_on_cnt,
    quantum_gre_bind_addr   => $quantum_gre_bind_addr,
    quantum_external_ipinfo => $external_ipinfo,
    tenant_network_type     => $tenant_network_type,
    segment_range           => $segment_range,
    cinder                  => $cinder,
    cinder_iscsi_bind_addr  => $cinder_iscsi_bind_addr,
    manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
    nv_physical_volume      => $nv_physical_volume,
    use_syslog              => $use_syslog,
    nova_rate_limits        => $nova_rate_limits,
    cinder_rate_limits      => $cinder_rate_limits,
    horizon_use_ssl         => $horizon_use_ssl,
  }
  if $::quantum and $quantum_network_node {
    class { '::openstack::quantum_router':
      db_host               => $controller_internal_address,
      service_endpoint      => $controller_internal_address,
      auth_host             => $controller_internal_address,
      internal_address      => $internal_address,
      public_interface      => $public_int,
      private_interface     => $private_interface,
      floating_range        => $floating_range,
      fixed_range           => $fixed_range,
      create_networks       => $create_networks,
      verbose               => $verbose,
      rabbit_password       => $rabbit_password,
      rabbit_user           => $rabbit_user,
      rabbit_ha_virtual_ip  => $controller_internal_address,
      rabbit_nodes           => [$controller_internal_address],
      quantum               => $quantum,
      quantum_user_password => $quantum_user_password,
      quantum_db_password   => $quantum_db_password,
      quantum_db_user       => $quantum_db_user,
      quantum_db_dbname     => $quantum_db_dbname,
      quantum_gre_bind_addr => $quantum_gre_bind_addr,
      quantum_network_node  => $quantum_network_node,
      quantum_netnode_on_cnt=> $quantum_netnode_on_cnt,
      tenant_network_type   => $tenant_network_type,
      segment_range         => $segment_range,
      external_ipinfo       => $external_ipinfo,
      api_bind_address      => $internal_address,
      use_syslog            => $use_syslog,
    }
  }
  class { 'openstack::auth_file':
    admin_password       => $admin_password,
    keystone_admin_token => $keystone_admin_token,
    controller_node      => $controller_internal_address,
  }
}


# Definition of OpenStack controller node.
node /fuel-controller-[\d+]/ {
  include stdlib
  class { 'operatingsystem::checksupported':
      stage => 'setup'
  }
  class {'nagios':
    proj_name       => $proj_name,
    services        => [
      'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
      'nova-consoleauth', 'nova-cert', 'nova-api', 'glance-api',
      'glance-registry','horizon', 'rabbitmq', 'mysql',
    ],
    whitelist       => ['127.0.0.1', $nagios_master],
    hostgroup       => 'controller',
  }
  class { 'simple_controller': } 
}

# Definition of OpenStack compute nodes.
node /fuel-compute-[\d+]/ {
  include stdlib
  class { 'operatingsystem::checksupported':
      stage => 'setup'
  }
  class {'::node_netconfig':
    mgmt_ipaddr    => $::internal_address,
    mgmt_netmask   => $::internal_netmask,
    public_ipaddr  => $::public_address,
    public_netmask => $::public_netmask,
    stage          => 'netconfig',
  }
  class {'nagios':
    proj_name       => $proj_name,
    services        => [
      'host-alive', 'nova-compute','nova-network','libvirt'
    ],
    whitelist       => ['127.0.0.1', $nagios_master],
    hostgroup       => 'compute',
  }

  class { 'openstack::compute':
    public_interface       => $public_int,
    private_interface      => $private_interface,
    internal_address       => $internal_address,
    libvirt_type           => 'kvm',
    fixed_range            => $fixed_range,
    network_manager        => $network_manager,
    network_config         => { 'vlan_start' => $vlan_start },
    multi_host             => $multi_host,
    sql_connection         => $sql_connection,
    nova_user_password     => $nova_user_password,
    rabbit_nodes           => [$controller_internal_address],
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    glance_api_servers     => "${controller_internal_address}:9292",
    vncproxy_host          => $controller_public_address,
    vnc_enabled            => true,
    ssh_private_key        => 'puppet:///ssh_keys/openstack',
    ssh_public_key         => 'puppet:///ssh_keys/openstack.pub',
    quantum                => $quantum,
    quantum_sql_connection => $quantum_sql_connection,
    quantum_user_password  => $quantum_user_password,
    quantum_host           => $controller_internal_address,
    tenant_network_type    => $tenant_network_type,
    service_endpoint       => $controller_internal_address,
    db_host                => $controller_internal_address,
    verbose                => $verbose,
    segment_range          => $segment_range,
    cinder                 => $cinder,
    manage_volumes          => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
    nv_physical_volume     => $nv_physical_volume,
    cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
    use_syslog             => $use_syslog,
    nova_rate_limits       => $nova_rate_limits,
    cinder_rate_limits     => $cinder_rate_limits
  }
}
