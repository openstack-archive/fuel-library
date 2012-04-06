class nova(
  # this is how to query all resources from our clutser
  $nova_cluster_id='localcluster',
  $sql_connection = false,
  # TODO maybe this should default to glance?
  $image_service = 'nova.image.local.LocalImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_api_servers = 'localhost:9292',
  $glance_host = 'localhost',
  $glance_port = '9292',
  $allow_admin_api = false,
  $rabbit_host = 'localhost',
  $rabbit_password='guest',
  $rabbit_port='5672',
  $rabbit_userid='guest',
  $rabbit_virtual_host='/',
  $network_manager = 'nova.network.manager.FlatManager',
  $flat_network_bridge = 'br100',
  $service_down_time = 60,
  $logdir = '/var/log/nova',
  $state_path = '/var/lib/nova',
  $lock_path = '/var/lock/nova',
  $verbose = false,
  $nodaemon = false,
  $periodic_interval = '60',
  $report_interval = '10',
  $root_helper = $::nova::params::root_helper
) inherits nova::params {

  # all nova_config resources should be applied
  # after the nova common package
  # before the file resource for nova.conf is managed
  # and before the post config resource
  Nova_config<| |> {
    require +> Package[$::nova::params::common_package_name],
    before  +> File['/etc/nova/nova.conf'],
    notify  +> Exec['post-nova_config']
  }

  File {
    require => Package[$::nova::params::common_package_name],
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
    name    =>$::nova::params::common_package_name,
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

  # I need to ensure that I better understand this resource
  # this is potentially constantly resyncing a central DB
  exec { "nova-db-sync":
    command     => "/usr/bin/nova-manage db sync",
    refreshonly => "true",
  }

  # used by debian/ubuntu in nova::network_bridge to refresh
  # interfaces based on /etc/network/interfaces
  exec { "networking-refresh":
    command     => "/sbin/ifdown -a ; /sbin/ifup -a",
    refreshonly => "true",
  }


  # query out the config for our db connection
  # TODO - I am not sure if resource collection should be the default
  if $sql_connection {
    nova_config { 'sql_connection': value => $sql_connection }
  } else{
    Nova_config<<| tag == $cluster_id and value == 'sql_connection' |>>
  }

  nova_config {
    'verbose': value => $verbose;
    'nodaemon': value => $nodaemon;
    'logdir': value => $logdir;
    'image_service': value => $image_service;
    'allow_admin_api': value => $allow_admin_api;
    'rabbit_host': value => $rabbit_host;
    'rabbit_password': value => $rabbit_password;
    'rabbit_port': value => $rabbit_port;
    'rabbit_userid': value => $rabbit_userid;
    'rabbit_virtual_host': value => $rabbit_virtual_host;
    # Following may need to be broken out to different nova services
    'state_path': value => $state_path;
    'lock_path': value => $lock_path;
    'service_down_time': value => $service_down_time;
    # These network entries wound up in the common
    # config b/c they have to be set by both compute
    # as well as controller.
    'network_manager': value => $network_manager;
    'use_deprecated_auth': value => true;
    'root_helper': value => $root_helper;
  }

  exec { 'post-nova_config':
    command => '/bin/echo "Nova config has changed"',
    refreshonly => true,
  }

  if $network_manager == 'nova.network.manager.FlatManager' {
    nova_config {
      'flat_network_bridge': value => $flat_network_bridge
    }
  }

  if $network_manager == 'nova.network.manager.FlatDHCPManager' {
    nova_config {
      'dhcpbridge': value => "/usr/bin/nova-dhcpbridge";
      'dhcpbridge_flagfile': value => "/etc/nova/nova.conf";
    }
  }

  if $image_service == 'nova.image.glance.GlanceImageService' {
    nova_config {
      'glance_api_servers': value => $glance_api_servers;
      'glance_host': value => $glance_host;
      'glance_port': value => $glance_port;
    }
  }
}
