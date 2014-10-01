$fuel_settings = parseyaml($astute_settings_yaml)

$openstack_version = {
  'keystone'   => 'installed',
  'glance'     => 'installed',
  'horizon'    => 'installed',
  'nova'       => 'installed',
  'novncproxy' => 'installed',
  'cinder'     => 'installed',
}

tag("${::fuel_settings['deployment_id']}::${::fuel_settings['environment']}")

#Stages configuration
stage {'zero': } ->
stage {'first': } ->
stage {'openstack-custom-repo': } ->
stage {'netconfig': } ->
stage {'corosync_setup': } ->
stage {'openstack-firewall': } -> Stage['main']

class begin_deployment ()
{
  $role = $::fuel_settings['role']
  notify { "***** Beginning deployment of node ${::hostname} with role $role *****": }
}

class {'begin_deployment': stage => 'zero' }

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

  $base_syslog_hash     = $::fuel_settings['base_syslog']
  $syslog_hash          = $::fuel_settings['syslog']


  $use_quantum = $::fuel_settings['quantum']
  if (!empty(filter_nodes($::fuel_settings['nodes'], 'role', 'ceph-osd')) or
    $::fuel_settings['storage']['volumes_ceph'] or
    $::fuel_settings['storage']['images_ceph'] or
    $::fuel_settings['storage']['objects_ceph']
  ) {
    $use_ceph = true
  } else {
    $use_ceph = false
  }


  if $use_quantum {
    prepare_network_config($::fuel_settings['network_scheme'])
    #
    $internal_int     = get_network_role_property('management', 'interface')
    $internal_address = get_network_role_property('management', 'ipaddr')
    $internal_netmask = get_network_role_property('management', 'netmask')
    #
    $public_int = get_network_role_property('ex', 'interface')
    if $public_int {
      $public_address = get_network_role_property('ex', 'ipaddr')
      $public_netmask = get_network_role_property('ex', 'netmask')
    }
    #
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

if ($::fuel_settings['neutron_mellanox']) {
  $mellanox_mode = $::fuel_settings['neutron_mellanox']['plugin']
} else {
  $mellanox_mode = 'disabled'
}

# This parameter specifies the verbosity level of log messages
# in openstack components config.
# Debug would have set DEBUG level and ignore verbose settings, if any.
# Verbose would have set INFO level messages
# In case of non debug and non verbose - WARNING, default level would have set.
$verbose = true
$debug = $::fuel_settings['debug']

### Storage Settings ###
# Determine if any ceph parts have been asked for.
# This will ensure that monitors are set up on controllers, even if no
#  ceph-osd roles during deployment


### Syslog ###
#TODO(bogdando) move logging options to astute.yaml
# Enable error messages reporting to rsyslog. Rsyslog must be installed in this case.
$use_syslog = $::fuel_settings['use_syslog'] ? { default=>true }
# Syslog facilities for main openstack services
# should vary (reserved usage)
# local1 is reserved for openstack-dashboard
$syslog_log_facility_glance     = 'LOG_LOCAL2'
$syslog_log_facility_cinder     = 'LOG_LOCAL3'
$syslog_log_facility_neutron    = 'LOG_LOCAL4'
$syslog_log_facility_nova       = 'LOG_LOCAL6'
$syslog_log_facility_keystone   = 'LOG_LOCAL7'
# could be the same
# local0 is free for use
$syslog_log_facility_murano     = 'LOG_LOCAL0'
$syslog_log_facility_heat       = 'LOG_LOCAL0'
$syslog_log_facility_sahara     = 'LOG_LOCAL0'
$syslog_log_facility_ceilometer = 'LOG_LOCAL0'

$nova_rate_limits = {
  'POST' => 100000,
  'POST_SERVERS' => 100000,
  'PUT' => 1000, 'GET' => 100000,
  'DELETE' => 100000
}
$cinder_rate_limits = {
  'POST' => 100000,
  'POST_SERVERS' => 100000,
  'PUT' => 100000, 'GET' => 100000,
  'DELETE' => 100000
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
  if ($::fuel_settings['neutron_mellanox']) and ($::fuel_settings['storage']['iser']) {
      class { 'mellanox_openstack::iser_rename':
                   stage => 'zero',
                   storage_parent => $::fuel_settings['neutron_mellanox']['storage_parent'],
                   iser_interface_name => $::fuel_settings['neutron_mellanox']['iser_interface_name'],
      }
  }
  class {"l23network::hosts_file": stage => 'netconfig', nodes => $nodes_hash }
  class {'l23network': use_ovs=>$use_quantum, stage=> 'netconfig'}
  if $use_quantum {
      class {'advanced_node_netconfig': stage => 'netconfig' }
  } else {
      class {'osnailyfacter::network_setup': stage => 'netconfig'}
  }

  class { 'openstack::firewall':
    stage => 'openstack-firewall',
    nova_vnc_ip_range => $::fuel_settings['management_network_range'],
  }

  $base_syslog_rserver  = {
    'remote_type' => 'tcp',
    'server' => $base_syslog_hash['syslog_server'],
    'port' => $base_syslog_hash['syslog_port']
  }

### TCP connections keepalives and failover related parameters ###
  # configure TCP keepalive for host OS.
  # Send 3 probes each 8 seconds, if the connection was idle
  # for a 30 seconds. Consider it dead, if there was no responces
  # during the check time frame, i.e. 30+3*8=54 seconds overall.
  # (note: overall check time frame should be lower then
  # nova_report_interval).
  class { 'openstack::keepalive' :
    stage           => 'netconfig',
    tcpka_time      => '30',
    tcpka_probes    => '8',
    tcpka_intvl     => '3',
    tcp_retries2    => '5',
  }

  # setting service down time and report interval
  # to 60 and 180 for Nova respectively to allow kernel
  # to kill dead connections
  # (see zendesk #1158 as well)
  $nova_report_interval = '60'
  $nova_service_down_time  = '180'

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
      show_timezone  => true,
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
      virtual        => str2bool($::is_virtual),
      # Rabbit doesn't support syslog directly
      rabbit_log_level => 'NOTICE',
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

  class { 'puppet::pull' :
    master_ip => $::fuel_settings['master_ip'],
  }
} # OS_COMMON ENDS



node default {
  case $::fuel_settings['deployment_mode'] {
    "singlenode": {
      include "osnailyfacter::cluster_simple"
      class {'os_common':}
      }
    "multinode": {
      include "osnailyfacter::cluster_simple"
      class {'os_common':}
      }
    /^(ha|ha_compact)$/: {
      include "osnailyfacter::cluster_ha"
      class {'os_common':}
      class {'corosync::commitorder': stage=>'main'}
      }
    "rpmcache": { include osnailyfacter::rpmcache }
  }
}
