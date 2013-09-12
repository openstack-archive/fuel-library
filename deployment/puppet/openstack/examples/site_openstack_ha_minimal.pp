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

# Public and Internal VIPs. These virtual addresses are required by HA topology and will be managed by keepalived.
$internal_virtual_ip = '10.0.0.253'
# Change this IP to IP routable from your 'public' network,
# e. g. Internet or your office LAN, in which your public
# interface resides
$public_virtual_ip   = '10.0.204.253'

case $::operatingsystem {
  'redhat' : {
          $queue_provider = 'qpid'
          $custom_mysql_setup_class = 'pacemaker_mysql'
  }
  default: {
    $queue_provider='rabbitmq'
    $custom_mysql_setup_class='galera'
  }
}

$nodes_harr = [
  {
    'name' => 'master',
    'role' => 'master',
    'internal_address' => '10.0.0.101',
    'public_address'   => '10.0.204.101',
  },
  {
    'name' => 'fuel-cobbler',
    'role' => 'cobbler',
    'internal_address' => '10.0.0.102',
    'public_address'   => '10.0.204.102',
  },
  {
    'name' => 'fuel-controller-01',
    'role' => 'primary-controller',
    'internal_address' => '10.0.0.103',
    'public_address'   => '10.0.204.103',
  },
  {
    'name' => 'fuel-controller-02',
    'role' => 'controller',
    'internal_address' => '10.0.0.104',
    'public_address'   => '10.0.204.104',
  },
  {
    'name' => 'fuel-controller-03',
    'role' => 'controller',
    'internal_address' => '10.0.0.105',
    'public_address'   => '10.0.204.105',
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
  },]
$nodes = $nodes_harr
$default_gateway = '10.0.204.1'

# Specify nameservers here.
# Need points to cobbler node IP, or to special prepared nameservers if you known what you do.
$dns_nameservers = ['10.0.204.1','8.8.8.8']

# Specify netmasks for internal and external networks.
$internal_netmask = '255.255.255.0'
$public_netmask = '255.255.255.0'


$node = filter_nodes($nodes,'name',$::hostname)
if empty($node) {
  fail("Node $::hostname is not defined in the hash structure")
}
$internal_address = $node[0]['internal_address']
$public_address = $node[0]['public_address']


$controllers = merge_arrays(filter_nodes($nodes,'role','primary-controller'), filter_nodes($nodes,'role','controller'))
$controller_internal_addresses = nodes_to_hash($controllers,'name','internal_address')
$controller_public_addresses = nodes_to_hash($controllers,'name','public_address')
$controller_hostnames = sort(keys($controller_internal_addresses))
$controller_internal_ipaddresses = sort(values($controller_internal_addresses))

#Set this to anything other than pacemaker if you do not want Quantum HA
#Also, if you do not want Quantum HA, you MUST enable $quantum_network_node
#on the ONLY controller
$ha_provider = 'pacemaker'
$use_unicast_corosync = true

$nagios = false
# Set nagios master fqdn
$nagios_master        = 'nagios-server.localdomain'
## proj_name  name of environment nagios configuration
$proj_name            = 'test'

#Specify if your installation contains multiple Nova controllers. Defaults to true as it is the most common scenario.
$multi_host              = true

# Specify different DB credentials for various services
# HA DB provided through pacemaker_mysql or galera
$mysql_root_password     = 'nova'
$admin_email             = 'openstack@openstack.org'
$admin_password          = 'nova'

validate_re($custom_mysql_setup_class,'galera|pacemaker_mysql')


$keystone_db_password    = 'nova'
$keystone_admin_token    = 'nova'

$glance_db_password      = 'nova'
$glance_user_password    = 'nova'

$nova_db_password        = 'nova'
$nova_user_password      = 'nova'

#AMQP backend rabbitmq or qpid
validate_re($queue_provider,  'rabbitmq|qpid')

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
$quantum_use_namespaces  = true

# a string "password" value that should be configured to authenticate requests for metadata
# from quantum-metadata-proxy to nova-api
$quantum_metadata_proxy_shared_secret = "connecting_nova-api_and_quantum-metadata-agent"
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
$tenant_network_type     = 'gre'

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
$segment_range   = '900:999'

# Set up OpenStack network manager. It is used ONLY in nova-network.
# Consult Openstack nova-network docs for possible values.
$network_manager = 'nova.network.manager.FlatDHCPManager'

# Assign floating IPs to VMs on startup automatically?
$auto_assign_floating_ip = false

# Database connection for Quantum configuration (quantum.conf)
#todo: check passing following line to quantum::*
$quantum_sql_connection  = "mysql://${quantum_db_user}:${quantum_db_password}@${$internal_virtual_ip}/${quantum_db_dbname}"


if $quantum {
  $public_int   = $public_br
  $internal_int = $internal_br
} else {
  $public_int   = $public_interface
  $internal_int = $internal_interface
}

$vips = { # Do not convert to ARRAY, It's can't work in 2.7
  public_old => {
    nic    => $public_int,
    ip     => $public_virtual_ip,
  },
  management_old => {
    nic    => $internal_int,
    ip     => $internal_virtual_ip,
  },
}

#Stages configuration
stage {'first': } ->
stage {'openstack-custom-repo': } ->
stage {'netconfig': } ->
stage {'corosync_setup': } ->
stage {'cluster_head': } ->
stage {'openstack-firewall': } -> Stage['main']


#Network configuration
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
$deployment_id = '89'

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

# Setup network address, which Cinder uses to export iSCSI targets.
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

### GLANCE ###

# Which backend to use for glance
# Supported backends are "swift" and "file"
$glance_backend          = 'file'

# Use loopback device for swift:
# set 'loopback' or false
# This parameter controls where swift partitions are located:
# on physical partitions or inside loopback devices.
$swift_loopback = false

### Glance and swift END ###



if $node[0]['role'] == 'primary-controller' {
  $primary_controller = true
} else {
  $primary_controller = false
}

# This parameter specifies the verbosity level of log messages
# in openstack components config.
# Debug would have set DEBUG level and ignore verbose settings, if any.
# Verbose would have set INFO level messages
# In case of non debug and non verbose - WARNING, default level would have set.
# Note: if syslog on, this default level may be configured (for syslog) with syslog_log_level option.
$verbose = true
$debug = false

### Syslog ###
# Enable error messages reporting to rsyslog. Rsyslog must be installed in this case.
$use_syslog = true
# Default log level would have been used, if non verbose and non debug
$syslog_log_level             = 'ERROR'
# Syslog facilities for main openstack services, choose any, may overlap if needed
# local0 is reserved for HA provisioning and orchestration services,
# local1 is reserved for openstack-dashboard
$syslog_log_facility_glance   = 'LOCAL2'
$syslog_log_facility_cinder   = 'LOCAL3'
$syslog_log_facility_quantum  = 'LOCAL4'
$syslog_log_facility_nova     = 'LOCAL6'
$syslog_log_facility_keystone = 'LOCAL7'

if $use_syslog {
  class { "::openstack::logging":
    stage          => 'first',
    role           => 'client',
    # use date-rfc3339 timestamps
    show_timezone => true,
    # log both locally include auth, and remote
    log_remote     => true,
    log_local      => true,
    log_auth_local => true,
    # keep four weekly log rotations, force rotate if 300M size have exceeded
    rotation       => 'weekly',
    keep           => '4',
    # should be > 30M
    limitsize      => '300M',
    # remote servers to send logs to
    rservers       => [{'remote_type'=>'udp', 'server'=>'master', 'port'=>'514'},],
    # should be true, if client is running at virtual node
    virtual        => true,
    # facilities
    syslog_log_facility_glance   => $syslog_log_facility_glance,
    syslog_log_facility_cinder   => $syslog_log_facility_cinder,
    syslog_log_facility_quantum  => $syslog_log_facility_quantum,
    syslog_log_facility_nova     => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    # Rabbit doesn't support syslog directly, should be >= syslog_log_level,
    # otherwise none rabbit's messages would have gone to syslog
    rabbit_log_level => $syslog_log_level,
    debug => $debug,
  }
}

# Example for server role class definition for remote logging node:
#   class {::openstack::logging:
#      role           => 'server',
#      log_remote     => false,
#      log_local      => true,
#      log_auth_local => true,
#      rotation       => 'daily',
#      keep           => '7',
#      limitsize      => '100M',
#      port           => '514',
#      proto          => 'udp',
#     #high precision timespamps
#      show_timezone  => true,
#     #should be true, if server is running at virtual node
#     #virtual        => false,
#   }
### Syslog END ###
case $::osfamily {
    "Debian":  {
       $rabbitmq_version_string = '2.8.7-1'
    }
    "RedHat": {
       $rabbitmq_version_string = '2.8.7-2.el6'
    }
}
#
# OpenStack packages and customized component versions to be installed.
# Use 'latest' to get the most recent ones or specify exact version if you need to install custom version.
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
Exec<| title == 'clocksync' |>->Exec<| title == 'glance-manage db_sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'nova-manage db sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'initial-db-sync' |>
Exec<| title == 'clocksync' |>->Exec<| title == 'post-nova_config' |>


### END OF PUBLIC CONFIGURATION PART ###
# Normally, you do not need to change anything after this string

# Globally apply an environment-based tag to all resources on each node.
tag("${::deployment_id}::${::environment}")


class { 'openstack::mirantis_repos':
  stage => 'openstack-custom-repo',
  type=>$mirror_type,
  enable_test_repo=>$enable_test_repo,
  repo_proxy=>$repo_proxy,
}

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


# Class for calling corosync::virtual_ip in the specifis stage
$vip_keys = keys($vips)
class virtual_ips () {
  cluster::virtual_ips { $vip_keys:
    vips => $vips,
  }
}



class compact_controller (
  $quantum_network_node = $quantum_netnode_on_cnt
) {
  class { 'openstack::controller_ha':
    controller_public_addresses   => $controller_public_addresses,
    controller_internal_addresses => $controller_internal_addresses,
    internal_address        => $internal_address,
    public_interface        => $public_int,
    internal_interface      => $internal_int,
    private_interface       => $private_interface,
    internal_virtual_ip     => $internal_virtual_ip,
    public_virtual_ip       => $public_virtual_ip,
    primary_controller      => $primary_controller,
    floating_range          => $floating_range,
    fixed_range             => $fixed_range,
    multi_host              => $multi_host,
    network_manager         => $network_manager,
    num_networks            => $num_networks,
    network_size            => $network_size,
    network_config          => { 'vlan_start' => $vlan_start },
    verbose                 => $verbose,
    debug                   => $debug,
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
    queue_provider          => $queue_provider,
    rabbit_password         => $rabbit_password,
    rabbit_user             => $rabbit_user,
    rabbit_nodes            => $controller_hostnames,
    qpid_password           => $rabbit_password,
    qpid_user               => $rabbit_user,
    qpid_nodes              => [$internal_virtual_ip],
    memcached_servers       => $controller_hostnames,
    export_resources        => false,
    glance_backend          => $glance_backend,
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
    galera_nodes            => $controller_hostnames,
    custom_mysql_setup_class => $custom_mysql_setup_class,
    nv_physical_volume      => $nv_physical_volume,
    use_syslog              => $use_syslog,
    syslog_log_level        => $syslog_log_level,
    syslog_log_facility_glance   => $syslog_log_facility_glance,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_facility_nova => $syslog_log_facility_nova,
    syslog_log_facility_keystone => $syslog_log_facility_keystone,
    nova_rate_limits        => $nova_rate_limits,
    horizon_use_ssl         => $horizon_use_ssl,
    use_unicast_corosync    => $use_unicast_corosync,
    cinder_rate_limits      => $cinder_rate_limits,
    ha_provider             => $ha_provider
  }
}

# Definition of OpenStack controller nodes.
node /fuel-controller-[\d+]/ {
  include stdlib
  class { 'operatingsystem::checksupported':
      stage => 'first'
  }

  class {'::node_netconfig':
      mgmt_ipaddr    => $::internal_address,
      mgmt_netmask   => $::internal_netmask,
      public_ipaddr  => $::public_address,
      public_netmask => $::public_netmask,
      stage          => 'netconfig',
  }
  if $nagios {
    class {'nagios':
      proj_name       => $proj_name,
      services        => [
        'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
        'nova-consoleauth', 'nova-cert', 'haproxy', 'nova-api', 'glance-api',
        'glance-registry','horizon', 'rabbitmq', 'mysql'
      ],
      whitelist       => ['127.0.0.1', $nagios_master],
      hostgroup       => 'controller',
    }
  }

  ###
  # cluster init
  class { '::cluster': stage => 'corosync_setup' } ->
  class { 'virtual_ips':
    stage => 'corosync_setup'
  }
  include ::haproxy::params
  class { 'cluster::haproxy':
    global_options   => merge($::haproxy::params::global_options, {'log' => "/dev/log local0"}),
    defaults_options => merge($::haproxy::params::defaults_options, {'mode' => 'http'}),
    stage => 'cluster_head',
  }
  #
  ###
  class { compact_controller: }
}


# Definition of OpenStack compute nodes.
node /fuel-compute-[\d+]/ {
  ## Uncomment lines bellow if You want
  ## configure network of this nodes
  ## by puppet.
  class {'::node_netconfig':
      mgmt_ipaddr    => $::internal_address,
      mgmt_netmask   => $::internal_netmask,
      public_ipaddr  => $::public_address,
      public_netmask => $::public_netmask,
      stage          => 'netconfig',
  }
  include stdlib
  class { 'operatingsystem::checksupported':
      stage => 'first'
  }

  if $nagios {
    class {'nagios':
      proj_name       => $proj_name,
      services        => [
        'host-alive', 'nova-compute','nova-network','libvirt'
      ],
      whitelist       => ['127.0.0.1', $nagios_master],
      hostgroup       => 'compute',
    }
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
    auto_assign_floating_ip => $auto_assign_floating_ip,
    sql_connection         => "mysql://nova:${nova_db_password}@${internal_virtual_ip}/nova",
    queue_provider         => $queue_provider,
    rabbit_nodes           => $controller_hostnames,
    rabbit_password        => $rabbit_password,
    rabbit_user            => $rabbit_user,
    rabbit_ha_virtual_ip   => $internal_virtual_ip,
    qpid_password          => $rabbit_password,
    qpid_user              => $rabbit_user,
    qpid_nodes             => [$internal_virtual_ip],
    glance_api_servers     => "${internal_virtual_ip}:9292",
    vncproxy_host          => $public_virtual_ip,
    verbose                => $verbose,
    debug                  => $debug,
    vnc_enabled            => true,
    nova_user_password     => $nova_user_password,
    cache_server_ip        => $controller_hostnames,
    service_endpoint       => $internal_virtual_ip,
    quantum                => $quantum,
    quantum_sql_connection => $quantum_sql_connection,
    quantum_user_password  => $quantum_user_password,
    quantum_host           => $internal_virtual_ip,
    tenant_network_type    => $tenant_network_type,
    segment_range          => $segment_range,
    cinder                 => $cinder,
    cinder_iscsi_bind_addr => $cinder_iscsi_bind_addr,
    manage_volumes         => $cinder ? { false => $manage_volumes, default =>$is_cinder_node },
    nv_physical_volume     => $nv_physical_volume,
    db_host                => $internal_virtual_ip,
    cinder_rate_limits     => $cinder_rate_limits,
    use_syslog             => $use_syslog,
    syslog_log_level       => $syslog_log_level,
    syslog_log_facility_quantum => $syslog_log_facility_quantum,
    syslog_log_facility_cinder => $syslog_log_facility_cinder,
    nova_rate_limits       => $nova_rate_limits,
  }
}

# Definition of OpenStack Quantum node.
node /fuel-quantum/ {
  include stdlib
  class { 'operatingsystem::checksupported':
      stage => 'first'
  }

  class {'::node_netconfig':
      mgmt_ipaddr    => $::internal_address,
      mgmt_netmask   => $::internal_netmask,
      public_ipaddr  => 'none',
      save_default_gateway => true,
      stage          => 'netconfig',
  }
  if ! $quantum_netnode_on_cnt {
    class { 'openstack::quantum_router':
      db_host               => $internal_virtual_ip,
      service_endpoint      => $internal_virtual_ip,
      auth_host             => $internal_virtual_ip,
      nova_api_vip          => $internal_virtual_ip,
      internal_address      => $internal_address,
      public_interface      => $public_int,
      private_interface     => $private_interface,
      floating_range        => $floating_range,
      fixed_range           => $fixed_range,
      create_networks       => $create_networks,
      verbose               => $verbose,
      debug                 => $debug,
      queue_provider        => $queue_provider,
      rabbit_password       => $rabbit_password,
      rabbit_user           => $rabbit_user,
      rabbit_nodes          => $controller_hostnames,
      rabbit_ha_virtual_ip  => $internal_virtual_ip,
      qpid_password         => $rabbit_password,
      qpid_user             => $rabbit_user,
      qpid_nodes            => [$internal_virtual_ip],
      quantum               => $quantum,
      quantum_user_password => $quantum_user_password,
      quantum_db_password   => $quantum_db_password,
      quantum_db_user       => $quantum_db_user,
      quantum_db_dbname     => $quantum_db_dbname,
      quantum_netnode_on_cnt=> false,
      quantum_network_node  => true,
      tenant_network_type   => $tenant_network_type,
      segment_range         => $segment_range,
      external_ipinfo       => $external_ipinfo,
      api_bind_address      => $internal_address,
      use_syslog            => $use_syslog,
      syslog_log_level      => $syslog_log_level,
      syslog_log_facility_quantum => $syslog_log_facility_quantum,
    }
    class { 'openstack::auth_file':
      admin_password       => $admin_password,
      keystone_admin_token => $keystone_admin_token,
      controller_node      => $internal_virtual_ip,
      before               => Class['openstack::quantum_router'],
    }
  }
}
