# This class is used to specify configuration parameters that are common
# across all nova services.
#
# ==Parameters
#
# [database_connection] Connection url to connect to nova database.
# [database_idle_timeout] Timeout before idle db connections are reaped.
# [image_service] Service used to search for and retrieve images. Optional.
#   Defaults to 'nova.image.local.LocalImageService'
# [glance_api_servers] List of addresses for api servers. Optional.
#   Defaults to localhost:9292.
# [memcached_servers] Use memcached instead of in-process cache. Supply a list of memcached server IP's:Memcached Port. Optional. Defaults to false.
# [rabbit_host] Location of rabbitmq installation. Optional. Defaults to localhost.
# [rabbit_port] Port for rabbitmq instance. Optional. Defaults to 5672.
# [rabbit_hosts] Location of rabbitmq installation. Optional. Defaults to undef.
# [rabbit_password] Password used to connect to rabbitmq. Optional. Defaults to guest.
# [rabbit_userid] User used to connect to rabbitmq. Optional. Defaults to guest.
# [rabbit_virtual_host] The RabbitMQ virtual host. Optional. Defaults to /.
# [auth_strategy]
# [service_down_time] maximum time since last check-in for up service. Optional.
#  Defaults to 60
# [logdir] Directory where logs should be stored. Optional. Defaults to '/var/log/nova'.
# [state_path] Directory for storing state. Optional. Defaults to '/var/lib/nova'.
# [lock_path] Directory for lock files. Optional. Distro specific default.
# [verbose] Rather to print more verbose output. Optional. Defaults to false.
# [periodic_interval] Seconds between running periodic tasks. Optional.
#   Defaults to '60'.
# [report_interval] Interval at which nodes report to data store. Optional.
#    Defaults to '10'.
# [root_helper] Command used for roothelper. Optional. Distro specific.
# [monitoring_notifications] A boolean specifying whether or not to send system usage data notifications out on the message queue. Optional, false by default. Only valid for stable/essex.
# [use_syslog] Use syslog for logging. Optional. Defaults to false.
# [log_facility] Syslog facility to receive log lines. Optional. Defaults to LOG_USER.
#
class nova(
  $ensure_package = 'present',
  # this is how to query all resources from our clutser
  $nova_cluster_id='localcluster',
  # note: sql_* deprecated for database_*
  $sql_connection = false,
  $sql_idle_timeout = false,
  $database_connection = false,
  $database_idle_timeout = 3600,
  $rpc_backend = 'nova.openstack.common.rpc.impl_kombu',
  $image_service = 'nova.image.glance.GlanceImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_api_servers = 'localhost:9292',
  $memcached_servers = false,
  $rabbit_host = 'localhost',
  $rabbit_hosts = false,
  $rabbit_password='guest',
  $rabbit_port='5672',
  $rabbit_userid='guest',
  $rabbit_virtual_host='/',
  $qpid_hostname = 'localhost',
  $qpid_port = '5672',
  $qpid_username = 'guest',
  $qpid_password = 'guest',
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
  $use_syslog = false,
  $log_facility = 'LOG_USER',
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
      'database/connection':   value => $database_connection_real, secret => true;
      'database/idle_timeout': value => $database_idle_timeout_real;
    }
  }

  nova_config { 'DEFAULT/image_service': value => $image_service }

  if $image_service == 'nova.image.glance.GlanceImageService' {
    if $glance_api_servers {
      nova_config { 'DEFAULT/glance_api_servers': value => $glance_api_servers }
    }
  }

  nova_config { 'DEFAULT/auth_strategy': value => $auth_strategy }

  if $memcached_servers {
    nova_config { 'DEFAULT/memcached_servers': value  => join($memcached_servers, ',') }
  } else {
    nova_config { 'DEFAULT/memcached_servers': ensure => absent }
  }

  if $rpc_backend == 'nova.openstack.common.rpc.impl_kombu' {
    # I may want to support exporting and collecting these
    nova_config {
      'DEFAULT/rabbit_password':     value => $rabbit_password, secret => true;
      'DEFAULT/rabbit_userid':       value => $rabbit_userid;
      'DEFAULT/rabbit_virtual_host': value => $rabbit_virtual_host;
    }

    if $rabbit_hosts {
      nova_config { 'DEFAULT/rabbit_hosts':     value => join($rabbit_hosts, ',') }
      nova_config { 'DEFAULT/rabbit_ha_queues': value => true }
    } else {
      nova_config { 'DEFAULT/rabbit_host':      value => $rabbit_host }
      nova_config { 'DEFAULT/rabbit_port':      value => $rabbit_port }
      nova_config { 'DEFAULT/rabbit_hosts':     value => "${rabbit_host}:${rabbit_port}" }
      nova_config { 'DEFAULT/rabbit_ha_queues': value => false }
    }
  }

  if $rpc_backend == 'nova.openstack.common.rpc.impl_qpid' {
    nova_config {
      'DEFAULT/qpid_hostname':               value => $qpid_hostname;
      'DEFAULT/qpid_port':                   value => $qpid_port;
      'DEFAULT/qpid_username':               value => $qpid_username;
      'DEFAULT/qpid_password':               value => $qpid_password, secret => true;
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

  nova_config {
    'DEFAULT/verbose':           value => $verbose;
    'DEFAULT/debug':             value => $debug;
    'DEFAULT/logdir':            value => $logdir;
    'DEFAULT/rpc_backend':       value => $rpc_backend;
    # Following may need to be broken out to different nova services
    'DEFAULT/state_path':        value => $state_path;
    'DEFAULT/lock_path':         value => $lock_path;
    'DEFAULT/service_down_time': value => $service_down_time;
    'DEFAULT/rootwrap_config':   value => $rootwrap_config;
  }

  if $monitoring_notifications {
    nova_config {
      'DEFAULT/notification_driver': value => 'nova.openstack.common.notifier.rpc_notifier'
    }
  }

  # Syslog configuration
  if $use_syslog {
    nova_config {
      'DEFAULT/use_syslog':           value => true;
      'DEFAULT/syslog_log_facility':  value => $log_facility;
    }
  } else {
    nova_config {
      'DEFAULT/use_syslog':           value => false;
    }
  }

  exec { 'post-nova_config':
    command     => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }

}
