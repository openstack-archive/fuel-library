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
# [rabbit_nodes] RabbitMQ nodes (HA/Cluster mode). Optional. Defaults to false.
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
# $rabbit_nodes = ['node001', 'node002', 'node003']
# add rabbit nodes hostname
#
class nova(
  $ensure_package = 'present',
  # this is how to query all resources from our clutser
  $nova_cluster_id='localcluster',
  $sql_connection = false,
  $image_service = 'nova.image.glance.GlanceImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_api_servers = 'localhost:9292',
  # for use rabbitmq in HA mode
  $rabbit_nodes = false,
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
  $root_helper = $::nova::params::root_helper,
  $monitoring_notifications = false,
  $api_bind_address = '0.0.0.0',
  $auth_strategy     = 'keystone',
  $auth_host         = '127.0.0.1',
  $auth_port         = 35357,
  $auth_protocol     = 'http',
  $admin_tenant_name = 'services',
  $admin_user        = 'nova',
  $admin_password    = 'passw0rd',
) inherits nova::params {


$auth_uri = "${auth_protocol}://${auth_host}:${auth_port}/v2.0"

  # all nova_config resources should be applied
  # after the nova common package
  # before the file resource for nova.conf is managed
  # and before the post config resource
  Nova_config<| |> {
    require +> Package['nova-common'],
    before  +> File['/etc/nova/nova.conf'],
    notify  +> Exec['post-nova_config']
  }

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

  package { 'python-nova':
    ensure  => $ensure_package,
    require => Package['python-greenlet']
  }

  # turn on rabbitmq ha/cluster mode
  if $rabbit_nodes {
    package { "patch":
      ensure => present
    }

    file { "/tmp/rmq-ha.patch":
      ensure => present,
      source => 'puppet:///modules/nova/rmq-ha.patch'
    }

    exec { 'patch-nova':
      unless  => "/bin/grep x-ha-policy /usr/lib/${::nova::params::python_path}/nova/rpc/impl_kombu.py",
      command => "/usr/bin/patch -p1 -d /usr/lib/${::nova::params::python_path}/nova </tmp/rmq-ha.patch",
      require => [ [File['/tmp/rmq-ha.patch']],[Package['patch', 'python-nova']]], 
    }
  }

  package { 'nova-common':
    name    => $::nova::params::common_package_name,
    ensure  => $ensure_package,
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

  # I need to ensure that I better understand this resource
  # this is potentially constantly resyncing a central DB
  exec { "nova-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    # refreshonly => "true",
    require     => [Package['nova-common'], Nova_config['sql_connection']],
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

  if $auth_strategy == 'keystone' {
    nova_config { 'use_deprecated_auth': value => false }
  } else {
    nova_config { 'use_deprecated_auth': value => true }
  }


  if $rabbit_nodes {
    nova_config { 'rabbit_addresses': value => inline_template("<%= @rabbit_nodes.map {|x| x+':5672'}.join ',' %>") }
  } else {
    if $rabbit_host {
      nova_config {
        'rabbit_host': value => $rabbit_host;
        'rabbit_port': value => $rabbit_port;
      }
    } else {
      Nova_config <<| title == 'rabbit_host' |>>
    }
  }

  # I may want to support exporting and collecting these
  nova_config {
    'rabbit_password': value => $rabbit_password;
    'rabbit_userid': value => $rabbit_userid;
    'rabbit_virtual_host': value => $rabbit_virtual_host;
    'rpc_backend': value => 'nova.rpc.impl_kombu';
  }


  nova_config {
    'verbose': value => $verbose;
    'logdir': value => $logdir;
    # Following may need to be broken out to different nova services
    'state_path': value => $state_path;
    'lock_path': value => $lock_path;
    'service_down_time': value => $service_down_time;
    'root_helper': value => $root_helper;
  }

  nova_config {
    'ec2_listen':           value => $api_bind_address;
    'osapi_compute_listen': value => $api_bind_address;
    'metadata_listen':      value => $api_bind_address;
    'osapi_volume_listen':  value => $api_bind_address;
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
  
  nova_config { 'api_paste_config': value => '/etc/nova/api-paste.ini'; }

  @file { '/etc/nova/api-paste.ini':
    content => template('nova/api-paste.ini.erb'),
    require => Package['nova-common'],
  }


}
