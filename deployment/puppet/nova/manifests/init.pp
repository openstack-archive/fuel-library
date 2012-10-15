# This class is used to specify configuration parameters that are common
# across all nova services.
#
# ==Parameters
#
# [sql_connection] Connection url to use to connect to nova sql database.
#  If specified as false, then it tries to collect the exported resource
#   Nova_config <<| title == 'sql_connection' |>>. Optional. Defaults to false.
# [image_service] Service used to search for and retrieve images. Optional.
#   Defaults to 'nova.image.local.LocalImageService'
# [glance_api_servers] List of addresses for api servers. Optional.
#   Defaults to localhost:9292.
# [rabbit_host] Location of rabbitmq installation. Optional. Defaults to localhost.
# [rabbit_password] Password used to connect to rabbitmq. Optional. Defaults to guest.
# [rabbit_port] Port for rabbitmq instance. Optional. Defaults to 5672.
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
#
class nova(
  # this is how to query all resources from our clutser
  $nova_cluster_id='localcluster',
  $sql_connection = false,
  $image_service = 'nova.image.glance.GlanceImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_api_servers = 'localhost:9292',
  $rabbit_host = 'localhost',
  $rabbit_password='guest',
  $rabbit_port='5672',
  $rabbit_userid='guest',
  $rabbit_virtual_host='/',
  $auth_strategy = 'keystone',
  $service_down_time = 60,
  $logdir = '/var/log/nova',
  $state_path = '/var/lib/nova',
  $lock_path = $::nova::params::lock_path,
  $verbose = false,
  $periodic_interval = '60',
  $report_interval = '10',
  $root_wrap_config = '/etc/nova/rootwrap.conf',
  # deprecated in folsom
  #$root_helper = $::nova::params::root_helper,
  $monitoring_notifications = false
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
    ensure => present,
    require => Package['python'],
  }

  class { 'nova::utilities': }

  # this anchor is used to simplify the graph between nova components by
  # allowing a resource to serve as a point where the configuration of nova begins
  anchor { 'nova-start': }

  package { "python-nova":
    ensure  => present,
    require => Package["python-greenlet"]
  }

  package { 'nova-common':
    name    => $::nova::params::common_package_name,
    ensure  => present,
    require => [Package["python-nova"], Anchor['nova-start']]
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
    mode    => '0751',
  }
  file { '/etc/nova/nova.conf':
    mode  => '0640',
  }

  # used by debian/ubuntu in nova::network_bridge to refresh
  # interfaces based on /etc/network/interfaces
  exec { "networking-refresh":
    command     => "/sbin/ifdown -a ; /sbin/ifup -a",
    refreshonly => "true",
  }


  # both the sql_connection and rabbit_host are things
  # that may need to be collected from a remote host
  if $sql_connection {
    if($sql_connection =~ /mysql:\/\/\S+:\S+@\S+\/\S+/) {
      require 'mysql::python'
    } elsif($sql_connection =~ /postgresql:\/\/\S+:\S+@\S+\/\S+/) {

    } elsif($sql_connection =~ /sqlite:\/\//) {

    } else {
      fail("Invalid db connection ${sql_connection}")
    }
    nova_config { 'sql_connection': value => $sql_connection }
  } else {
    Nova_config <<| title == 'sql_connection' |>>
  }

  nova_config { 'image_service': value => $image_service }

  if $image_service == 'nova.image.glance.GlanceImageService' {
    if $glance_api_servers {
      nova_config { 'glance_api_servers': value => $glance_api_servers }
    } else {
      # TODO this only supports setting a single address for the api server
      Nova_config <<| title == glance_api_servers |>>
    }
  }

  nova_config { 'auth_strategy': value => $auth_strategy }

  if $rabbit_host {
    nova_config { 'rabbit_host': value => $rabbit_host }
  } else {
    Nova_config <<| title == 'rabbit_host' |>>
  }
  # I may want to support exporting and collecting these
  nova_config {
    'rabbit_password':     value => $rabbit_password;
    'rabbit_port':         value => $rabbit_port;
    'rabbit_userid':       value => $rabbit_userid;
    'rabbit_virtual_host': value => $rabbit_virtual_host;
  }

  nova_config {
    'verbose':           value => $verbose;
    'logdir':            value => $logdir;
    # Following may need to be broken out to different nova services
    'state_path':        value => $state_path;
    'lock_path':         value => $lock_path;
    'service_down_time': value => $service_down_time;
    'root_wrap_config':  value => $root_wrap_config;
  }


  if $monitoring_notifications {
    nova_config {
      'notification_driver': value => 'nova.notifier.rabbit_notifier'
    }
  }


  exec { 'post-nova_config':
    command => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }

}
