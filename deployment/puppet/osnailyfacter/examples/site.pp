$fuel_settings = parseyaml($astute_settings_yaml)

$openstack_version = {
  'keystone'   => 'latest',
  'glance'     => 'latest',
  'horizon'    => 'latest',
  'nova'       => 'latest',
  'novncproxy' => 'latest',
  'cinder'     => 'latest',
}

tag("${::fuel_settings['deployment_id']}::${::fuel_settings['environment']}")

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

if $::fuel_settings['nodes'] {
  $nodes_hash = $::fuel_settings['nodes']

  $dns_nameservers=$::fuel_settings['dns_nameservers']
  $node = filter_nodes($nodes_hash,'name',$::hostname)
  if empty($node) {
    fail("Node $::hostname is not defined in the hash structure")
  }

  $default_gateway = $node[0]['default_gateway']

  if $::fuel_settings['storage']['glance'] == 'ceph' {
    $use_ceph=true
  } else {
    $use_ceph=false
  }

  $base_syslog_hash     = $::fuel_settings['base_syslog']
  $syslog_hash          = $::fuel_settings['syslog']

  if !$::fuel_settings['savanna'] {
    $savanna_hash={}
  } else {
    $savanna_hash = $::fuel_settings['savanna']
  }

  if !$::fuel_settings['murano'] {
    $murano_hash = {}
  } else {
    $murano_hash = $::fuel_settings['murano']
  }

  if !$::fuel_settings['heat'] {
    $heat_hash = {}
  } else {
    $heat_hash = $::fuel_settings['heat']
  }

  $use_quantum = $::fuel_settings['quantum']
  if $use_quantum {
    prepare_network_config($::fuel_settings['network_scheme'])
    $public_int   = get_network_role_property('ex', 'interface')
    $internal_int = get_network_role_property('management', 'interface')
    $internal_address = get_network_role_property('management', 'ipaddr')
    $internal_netmask = get_network_role_property('management', 'netmask')
    $public_address = get_network_role_property('ex', 'ipaddr')
    $public_netmask = get_network_role_property('ex', 'netmask')
    $storage_address = get_network_role_property('storage', 'ipaddr')
    $storage_netmask = get_network_role_property('storage', 'netmask')
  } else {
    $internal_address = $node[0]['internal_address']
    $internal_netmask = $node[0]['internal_netmask']
    $public_address = $node[0]['public_address']
    $public_netmask = $node[0]['public_netmask']
    $storage_address = $node[0]['storage_address']
    $storage_netmask = $node[0]['storage_netmask']
    $public_br = $node[0]['public_br']
    $internal_br = $node[0]['internal_br']
    $public_int   = $::fuel_settings['public_interface']
    $internal_int = $::fuel_settings['management_interface']
  }
}

# This parameter specifies the verbosity level of log messages
# in openstack components config.
# Debug would have set DEBUG level and ignore verbose settings, if any.
# Verbose would have set INFO level messages
# In case of non debug and non verbose - WARNING, default level would have set.
# Note: if syslog on, this default level may be configured (for syslog) with syslog_log_level option.
$verbose = $::fuel_settings['verbose']
$debug = $::fuel_settings['debug']

### Storage Settings ###
# Determine if any ceph parts have been asked for.
# This will ensure that monitors are set up on controllers, even if no
#  ceph-osd roles during deployment

if (filter_nodes($::fuel_settings['nodes'], 'role', 'ceph-osd') or
    $::fuel_settings['storage']['volumes_ceph'] or
    $::fuel_settings['storage']['images_ceph'] or
    $::fuel_settings['storage']['objects_ceph']
) {
  $use_ceph = true
} else {
  $use_ceph = false
}


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
class advanced_node_netconfig {
    $sdn = generate_network_config()
    notify {"SDN: ${sdn}": }
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
  class {"l23network::hosts_file": stage => 'netconfig', nodes => $nodes_hash }
  class {'l23network': use_ovs=>$use_quantum, stage=> 'netconfig'}
  if $use_quantum {
      class {'advanced_node_netconfig': stage => 'netconfig' }
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
    source  => $::fuel_settings['master_ip'],
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }

  firewall {'004 remote puppet ':
    sport   => [ 8140 ],
    source  => $master_ip,
    proto   => 'tcp',
    action  => 'accept',
    require => Class['openstack::firewall'],
  }
}



node default {
  case $::fuel_settings['deployment_mode'] {
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
    "ha_full": {
      include "osnailyfacter::cluster_ha_full"
      class {'os_common':}
      }
    "rpmcache": { include osnailyfacter::rpmcache }
  }
}
