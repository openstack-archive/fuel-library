class nova(
  # this is how to query all resources from our clutser
  $nova_cluster_id='localcluster',
  $sql_connection = false,
  $image_service = 'nova.image.local.LocalImageService',
  # these glance params should be optional
  # this should probably just be configured as a glance client
  $glance_host = undef,
  $glance_port = undef,
  $allow_admin_api = undef,
  $rabbit_host = 'localhost',
  $rabbit_password='guest',
  $rabbit_port='5672',
  $rabbit_userid='guest',
  $rabbit_virtual_host='/',
  # Following may need to be broken out to different nova services
  $service_down_time = undef,
  $quota_instances = 10,
  $quota_cores = 20,
  $quota_volumes = 10,
  $quota_gigabytes = 1000,
  $quota_floating_ips = 10,
  $quota_metadata_items = 128,
  $quota_max_injected_files = 5,
  $quota_max_injected_file_content_bytes = 10240,
  $quota_max_injected_file_path_bytes = 255,
  $logdir = '/var/log/nova',
  $state_path = '/var/lib/nova',
  $lock_path = '/var/lock/nova',
  $verbose = false,
  $nodaemon = false,
  $periodic_interval = '60',
  $report_interval = '10'
) {

  # TODO - why is this required?
  package { "python-greenlet": ensure => present }

  class { 'nova::utilities': }
  package { ["python-nova", "nova-common", "nova-doc"]:
    ensure  => present,
    require => Package["python-greenlet"]
  }
  group { 'nova':
    ensure => present
  }
  user { 'nova':
    ensure => present,
    gid    => 'nova',
  }
  file { $logdir:
    ensure  => directory,
    mode    => '751',
    owner   => 'nova',
    group   => 'nova',
    require => Package['nova-common'],
  }
  file { '/etc/nova/nova.conf':
    owner => 'nova',
    group => 'nova',
    mode  => '0640',
  }
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
    'quota_instances': value => $quota_instances; 
    'quota_cores': value => $quota_cores;
    'quota_volumes': value => $quota_volumes;
    'quota_gigabytes': value => $quota_gigabytes;
    'quota_floating_ips': value => $quota_floating_ips;
    'quota_metadata_items': value => $quota_metadata_items;
    'quota_max_injected_files': value => $quota_max_injected_files;
    'quota_max_injected_file_content_bytes': value => $quota_max_injected_file_content_bytes;
    'quota_max_injected_file_path_bytes': value => $quota_max_injected_file_path_bytes
  }

  if $image_service == 'nova.image.glance.GlanceImageService' {
    nova_config {
      'glance_host': value => $glance_host;
      'glance_port': value => $glance_port; # default is 9292
    }
  }

  Nova_config<| |> { 
    require +> Package["nova-common"],
    before +> File['/etc/nova/nova.conf']
  }
}
