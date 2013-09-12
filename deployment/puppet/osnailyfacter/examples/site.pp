$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
  'cinder'     => 'latest',
}

tag("${deployment_id}::${::environment}")

#Stages configuration
stage {'first': } ->
stage {'openstack-custom-repo': } ->
stage {'netconfig': } ->
stage {'corosync_setup': } ->
stage {'cluster_head': } ->
stage {'openstack-firewall': } -> Stage['main']

stage {'glance-image':
  require => Stage['main'],
}



if $nodes != undef {
  $nodes_hash = parsejson($nodes)

  $node = filter_nodes($nodes_hash,'name',$::hostname)
  if empty($node) {
    fail("Node $::hostname is not defined in the hash structure")
  }

  $default_gateway = $node[0]['default_gateway']
  $internal_address = $node[0]['internal_address']
  $internal_netmask = $node[0]['internal_netmask']
  $public_address = $node[0]['public_address']
  $public_netmask = $node[0]['public_netmask']
  $storage_address = $node[0]['storage_address']
  $storage_netmask = $node[0]['storage_netmask']
  $public_br = $node[0]['public_br']
  $internal_br = $node[0]['internal_br']
  $base_syslog_hash     = parsejson($::base_syslog)
  $syslog_hash          = parsejson($::syslog)

  $use_quantum = str2bool($quantum)
  if $use_quantum {
    $public_int   = $public_br
    $internal_int = $internal_br
  } else {
    $public_int   = $public_interface
    $internal_int = $management_interface
  }
}

# This parameter specifies the verbosity level of log messages
# in openstack components config.
# Debug would have set DEBUG level and ignore verbose settings, if any.
# Verbose would have set INFO level messages
# In case of non debug and non verbose - WARNING, default level would have set.
# Note: if syslog on, this default level may be configured (for syslog) with syslog_log_level option.
# $verbose = true
# $debug = false

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


###
class node_netconfig (
  $mgmt_ipaddr,
  $mgmt_netmask  = '255.255.255.0',
  $public_ipaddr = undef,
  $public_netmask= '255.255.255.0',
  $save_default_gateway=false,
  $quantum = $use_quantum,
  $default_gateway
) {
  if $use_quantum {
    l23network::l3::create_br_iface {'mgmt':
      interface => $management_interface, # !!! NO $internal_int /sv !!!
      bridge    => $internal_br,
      ipaddr    => $mgmt_ipaddr,
      netmask   => $mgmt_netmask,
      dns_nameservers  => $dns_nameservers,
      gateway => $default_gateway,
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
      gateway => $default_gateway
    }
  }
  l23network::l3::ifconfig {$fixed_interface: ipaddr=>'none' }
}

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

class os_common {
  class {'l23network': use_ovs=>$use_quantum, stage=> 'netconfig'}
  if $deployment_source == 'cli' {
    class {'::node_netconfig':
      mgmt_ipaddr    => $internal_address,
      mgmt_netmask   => $internal_netmask,
      public_ipaddr  => $public_address,
      public_netmask => $public_netmask,
      stage          => 'netconfig',
      default_gateway => $default_gateway
    }
  } else {
    class {'osnailyfacter::network_setup': stage => 'netconfig'}
  }

  class {'openstack::firewall': stage => 'openstack-firewall'}

  $base_syslog_rserver  = {
    'remote_type' => 'udp',
    'server' => $base_syslog_hash['syslog_server'],
    'port' => $base_syslog_hash['syslog_port']
  }

  $syslog_rserver = {
    'remote_type' => $syslog_hash['syslog_transport'],
    'server' => $syslog_hash['syslog_server'],
    'port' => $syslog_hash['syslog_port'],
  }
  if $syslog_hash['syslog_server'] != "" and $syslog_hash['syslog_port'] != "" and $syslog_hash['syslog_transport'] != "" {
    $rservers = [$base_syslog_rserver, $syslog_rserver]
  } else {
    $rservers = [$base_syslog_rserver]
  }

  if $use_syslog {
    class { "::openstack::logging":
      stage          => 'first',
      role           => 'client',
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
      rservers       => $rservers,
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
      # debug mode
      debug          => $debug ? { 'true' => true, true => true, default=> false },
    }
  }

  #case $role {
    #    /controller/:          { $hostgroup = 'controller' }
    #    /swift-proxy/: { $hostgroup = 'swift-proxy' }
    #    /storage/:{ $hostgroup = 'swift-storage'  }
    #    /compute/: { $hostgroup = 'compute'  }
    #    /cinder/: { $hostgroup = 'cinder'  }
    #    default: { $hostgroup = 'generic' }
    #}

    #  if $nagios != 'false' {
    #  class {'nagios':
    #    proj_name       => $proj_name,
    #    services        => [
    #      'host-alive','nova-novncproxy','keystone', 'nova-scheduler',
    #      'nova-consoleauth', 'nova-cert', 'haproxy', 'nova-api', 'glance-api',
    #      'glance-registry','horizon', 'rabbitmq', 'mysql',
    #    ],
    #    whitelist       => ['127.0.0.1', $nagios_master],
    #    hostgroup       => $hostgroup ,
    #  }
    # }

  # Workaround for fuel bug with firewall
  firewall {'003 remote rabbitmq ':
    sport   => [ 4369, 5672, 41055, 55672, 61613 ],
    source  => $master_ip,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }
}



node default {
  case $deployment_mode {
    "singlenode": {
      include "osnailyfacter::cluster_simple"
      class {'os_common':}
      }
    "multinode": {
      include osnailyfacter::cluster_simple
      class {'os_common':}
      }
    /^(ha|ha_compact)$/: {
      include "osnailyfacter::cluster_ha"
      class {'os_common':}
      }
     'ha_full': {
      include "osnailyfacter::cluster_ha_full"
      class {'os_common':}
      }
    "rpmcache": { include osnailyfacter::rpmcache }
  }

}
