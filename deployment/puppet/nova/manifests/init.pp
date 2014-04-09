# This class is used to specify configuration parameters that are common
# across all nova services.
#
# ==Parameters
#
# [database_connection] Connection url to connect to nova database.
#  If specified as false, then it tries to collect the exported resource
#   Nova_config <<| tag == "${::deployment_id}::${::environment}" and title == 'sql_connection' |>>. Optional. Defaults to false.
# [database_idle_timeout] Timeout before idle db connections are reaped.
# [image_service] Service used to search for and retrieve images. Optional.
#   Defaults to 'nova.image.local.LocalImageService'
# [glance_api_servers] List of addresses for api servers. Optional.
#   Defaults to localhost:9292.
# [memcached_servers] Use memcached instead of in-process cache. Supply a list of memcached server IP's:Memcached Port. Optional. Defaults to false.
# [amqp_hosts] Location of rabbitmq installation. Optional. Defaults to localhost.
# [amqp_user] User used to connect to rabbitmq. Optional. Defaults to guest.
# [amqp_password] Password used to connect to rabbitmq. Optional. Defaults to guest.
# [rabbit_virtual_host] The RabbitMQ virtual host. Optional. Defaults to /.
# [auth_strategy]
# [service_down_time] maximum time since last check-in for up service. Optional.
#  Defaults to 60
# [logdir] Directory where logs should be stored. Optional. Defaults to '/var/log/nova'.
# [state_path] Directory for storing state. Optional. Defaults to '/var/lib/nova'.
# [lock_path] Directory for lock files. Optional. Distro specific default.
# [verbose] Rather to print more verbose (INFO+) output. If non verbose and non debug, would give syslog_log_level (default is WARNING) output.
#  Optional. Defaults to false.
# [debug] Rather to print even more verbose (DEBUG+) output. If true, would ignore verbose option. Optional. Defaults to false.
# [periodic_interval] Seconds between running periodic tasks. Optional.
#   Defaults to '60'.
# [report_interval] Interval at which nodes report to data store. Optional.
#    Defaults to '10'.
# [root_helper] Command used for roothelper. Optional. Distro specific.
# [monitoring_notifications] A boolean specifying whether or not to send system usage data notifications out on the message queue. Optional, false by default. Only valid for stable/essex.
# [rabbit_nodes] = ['node001', 'node002', 'node003']
#    Add rabbit nodes hostname
# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Defaults to 'LOG_LOCAL6'.
# [syslog_log_level] logging level for non verbose and non debug mode. Optional. Defaults to 'WARNING'.
#
class nova(
  $ensure_package = 'present',
  # this is how to query all resources from our clutser
  $nova_cluster_id='localcluster',
  # note: sql_* deprecated for database_*
  $sql_connection = false,
  $use_syslog = false,
  $syslog_log_facility = 'LOG_LOCAL6',
  $syslog_log_level = 'WARNING',
  $sql_idle_timeout = false,
  $database_connection = false,
  $database_idle_timeout = 3600,
  $image_service = 'nova.image.glance.GlanceImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_api_servers = 'localhost:9292',
  $memcached_servers = false,
  # RPC
  $queue_provider = 'rabbitmq',
  $amqp_hosts = 'localhost',
  $amqp_user = 'guest',
  $amqp_password = 'guest',
  $rabbit_ha_queues = false,
  $rabbit_virtual_host='/',
  $qpid_reconnect = true,
  $qpid_reconnect_timeout = 0,
  $qpid_reconnect_limit = 0,
  $qpid_reconnect_interval_min = 0,
  $qpid_reconnect_interval_max = 0,
  $qpid_reconnect_interval = 0,
  $qpid_heartbeat = 60,
  $qpid_protocol = 'tcp',
  $qpid_tcp_nodelay = true,
  $auth_strategy = 'keystone',
  $service_down_time = 60,
  $logdir = '/var/log/nova',
  $state_path = '/var/lib/nova',
  $lock_path = $::nova::params::lock_path,
  $verbose = false,
  $debug = false,
  $periodic_interval = '60',
  $report_interval = '10',
  $rootwrap_config = '/etc/nova/rootwrap.conf',
  # deprecated in folsom
  #$root_helper = $::nova::params::root_helper,
  $monitoring_notifications = false,
  $api_bind_address = '0.0.0.0',
  $remote_syslog_server = '127.0.0.1',
  $idle_timeout = '3600',
  $max_pool_size = '10',
  $max_overflow = '30',
  $max_retries = '-1',
) inherits nova::params {

  # all nova_config resources should be applied
  # after the nova common package
  # before the file resource for nova.conf is managed
  # and before the post config resource
  Package['nova-common'] -> Nova_config<| |> -> File['/etc/nova/nova.conf']
  Nova_config<| |> ~> Exec['post-nova_config']

  File {
    require => Package['nova-common'],
    owner   => 'nova',
    group   => 'nova',
  }

  # TODO - see if these packages can be removed
  # they should be handled as package deps by the OS
  package { 'python':
    ensure => present,
  }
  package { 'python-greenlet':
    ensure  => present,
    require => Package['python'],
  }

  class { 'nova::utilities': }

  # this anchor is used to simplify the graph between nova components by
  # allowing a resource to serve as a point where the configuration of nova begins
  anchor { 'nova-start': }

  package { 'python-nova':
    ensure  => $ensure_package,
    require => Package['python-greenlet']
  }

  # turn on rabbitmq ha/cluster mode
  if $queue_provider == 'rabbitmq' and $rabbit_ha_queues {
    Nova_config['DEFAULT/rabbit_ha_queues'] -> Nova::Generic_service<| title != 'api' |>
    nova_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
  }

  if (defined(Exec['update-kombu']))
  {
    Exec['update-kombu'] -> Nova::Generic_service<||>
  }
  package { 'nova-common':
    ensure  => $ensure_package,
    name    => $::nova::params::common_package_name,
    require => [Package['python-nova'], Anchor['nova-start']]
  }

  group { 'nova':
    ensure  => present,
    system  => true,
    require => Package['nova-common'],
  }
  user { 'nova':
    ensure  => present,
    gid     => 'nova',
    system  => true,
    require => Package['nova-common'],
  }

  file { $logdir:
    ensure  => directory,
    mode    => '0750',
  }
  file { '/etc/nova/nova.conf':
    mode  => '0640',
  }

  # used by debian/ubuntu in nova::network_bridge to refresh
  # interfaces based on /etc/network/interfaces
  exec { 'networking-refresh':
    command     => '/sbin/ifdown -a ; /sbin/ifup -a',
    refreshonly => true,
  }

  if $sql_connection {
    warning('sql_connection deprecated for database_connection')
    $database_connection_real = $sql_connection
  } else {
    $database_connection_real = $database_connection
  }

  if $sql_idle_timeout {
    warning('sql_idle_timeout deprecated for database_idle_timeout')
    $database_idle_timeout_real = $sql_idle_timeout
  } elsif $idle_timeout {
    warning('sql_idle_timeout deprecated for database_idle_timeout')
    $database_idle_timeout_real = $idle_timeout
  } else {
    $database_idle_timeout_real = $database_idle_timeout
  }

  # both the database_connection and rabbit_host are things
  # that may need to be collected from a remote host
  if $database_connection_real {
    if($database_connection_real =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
      require 'mysql::python'
    } elsif($database_connection_real =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

    } elsif($database_connection_real =~ /sqlite:\/\//) {

    } else {
      fail("Invalid db connection ${database_connection_real}")
    }
    nova_config {
      'database/connection':    value => $database_connection_real, secret => true;
      'database/idle_timeout':  value => $database_idle_timeout_real;
      'database/max_pool_size': value => $max_pool_size;
      'database/max_retries':   value => $max_retries;
      'database/max_overflow':  value => $max_overflow;
    }
  } else {
    Nova_config <<| tag == "${::deployment_id}::${::environment}" and title == 'sql_connection' |>>
  }
  nova_config { 'DEFAULT/allow_resize_to_same_host': value => 'True' }
  nova_config { 'DEFAULT/image_service': value => $image_service }

  if $image_service == 'nova.image.glance.GlanceImageService' {
    if $glance_api_servers {
      nova_config { 'DEFAULT/glance_api_servers': value => $glance_api_servers }
    } else {
      # TODO this only supports setting a single address for the api server
      Nova_config <<| tag == "${::deployment_id}::${::environment}" and title == 'glance_api_servers' |>>
    }
  }

  nova_config { 'DEFAULT/auth_strategy': value => $auth_strategy }

  if $memcached_servers {
    if is_array($memcached_servers)
    {
        nova_config { 'DEFAULT/memcached_servers': value  => join($memcached_servers, ',') }
    }
    else {
            nova_config { 'DEFAULT/memcached_servers': value  => $memcached_servers }
         }
  } else {
    nova_config { 'DEFAULT/memcached_servers': ensure => absent }
  }

  # I may want to support exporting and collecting these
  case $queue_provider {
    "rabbitmq": {
      nova_config {
        'DEFAULT/rabbit_hosts':        value => $amqp_hosts;
        'DEFAULT/rabbit_userid':       value => $amqp_user;
        'DEFAULT/rabbit_password':     value => $amqp_password;
        'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
        'DEFAULT/rpc_backend':         value => 'nova.openstack.common.rpc.impl_kombu';
      }
    }
    "qpid": {
      nova_config {
        'DEFAULT/qpid_hosts':                  value => $amqp_hosts;
        'DEFAULT/qpid_username':               value => $amqp_user;
        'DEFAULT/qpid_password':               value => $rabbit_virtual_host;
        'DEFAULT/rpc_backend':                 value => 'nova.openstack.common.rpc.impl_qpid';
        'DEFAULT/qpid_reconnect':              value => $qpid_reconnect;
        'DEFAULT/qpid_reconnect_timeout':      value => $qpid_reconnect_timeout;
        'DEFAULT/qpid_reconnect_limit':        value => $qpid_reconnect_limit;
        'DEFAULT/qpid_reconnect_interval_min': value => $qpid_reconnect_interval_min;
        'DEFAULT/qpid_reconnect_interval_max': value => $qpid_reconnect_interval_max;
        'DEFAULT/qpid_reconnect_interval':     value => $qpid_reconnect_interval;
        'DEFAULT/qpid_heartbeat':              value => $qpid_heartbeat;
        'DEFAULT/qpid_protocol':               value => $qpid_protocol;
        'DEFAULT/qpid_tcp_nodelay':            value => $qpid_tcp_nodelay;
      }
    }
  }

  nova_config {
    'DEFAULT/verbose':              value => $verbose;
    'DEFAULT/debug':                value => $debug;
    # Following may need to be broken out to different nova services
    'DEFAULT/state_path':           value => $state_path;
    'DEFAULT/lock_path':            value => $lock_path;
    'DEFAULT/service_down_time':    value => $service_down_time;
    'DEFAULT/rootwrap_config':      value => $rootwrap_config;
    'DEFAULT/ec2_listen':           value => $api_bind_address;
    'DEFAULT/osapi_compute_listen': value => $api_bind_address;
    'DEFAULT/metadata_listen':      value => $api_bind_address;
    'DEFAULT/osapi_volume_listen':  value => $api_bind_address;
  }

  if $monitoring_notifications {
    nova_config {
      'DEFAULT/notification_driver': value => 'nova.openstack.common.notifier.rpc_notifier'
    }
  }

#Configure logging in nova.conf
if $use_syslog and !$debug { #syslog and nondebug case
  nova_config {
     'DEFAULT/log_config': value => "/etc/nova/logging.conf";
     'DEFAULT/use_syslog': value =>  true;
     'DEFAULT/syslog_log_facility': value =>  $syslog_log_facility;
  }
  file {"nova-logging.conf":
    content => template('nova/logging.conf.erb'),
    path => "/etc/nova/logging.conf",
    require => File[$logdir],
  }
  # We must notify services to apply new logging rules
  File['nova-logging.conf'] ~> Nova::Generic_service <| |>
  File['nova-logging.conf'] ~> Service <| title == 'nova-api'|>
  File['nova-logging.conf'] ~> Service <| title == 'nova-compute'|>
} else { #other syslog debug or nonsyslog debug/nondebug cases
  nova_config {
   'DEFAULT/log_config': ensure=> absent;
   'DEFAULT/logdir': value=> $logdir;
   'DEFAULT/use_syslog': value =>  false;
  }
}

  exec { 'post-nova_config':
    command     => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }

}
