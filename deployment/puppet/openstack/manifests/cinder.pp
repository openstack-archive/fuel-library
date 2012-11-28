class openstack::cinder(
  $sql_connection,
  $cinder_user_password,
  $rabbit_password,
  $rabbit_host     = false,
  $rabbit_nodes    = ['127.0.0.1'],
  $volume_group    = 'cinder-volumes',
  $physical_volume = undef,
  $manage_volumes  = false,
  $enabled         = true,
  $purge_cinder_config = true,
  $auth_host          = '127.0.0.1',
  $bind_host          = '0.0.0.0',
) {
  include cinder::params
  #  if ($purge_cinder_config) {
  # resources { 'cinder_config':
  #   purge => true,
  # }   
  #}
  if $rabbit_nodes {
    $rabbit_hosts = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
    file { "/tmp/rmq-cinder-ha.patch":
      ensure => present,
      source => 'puppet:///modules/cinder/rmq-cinder-ha.patch'
    }

    exec { 'patch-cinder-rabbitmq':
      unless  => "/bin/grep x-ha-policy /usr/lib/${::cinder::params::python_path}/cinder/openstack/common/rpc/impl_kombu.py",
      command => "/usr/bin/patch -p1 -N -r - -d /usr/lib/${::cinder::params::python_path}/cinder </tmp/rmq-cinder-ha.patch",
      returns => [0, 1],
      require => [ [File['/tmp/rmq-cinder-ha.patch']],[Package['patch', 'python-cinder']]],
    }
    #    exec { 'patch-nova-mysql':
    #  unless  => "/bin/grep sql_inc_retry_interval /usr/lib/${::nova::params::python_path}/nova/flags.py",
    #  command => "/usr/bin/patch -p1 -N -r - -d /usr/lib/${::nova::params::python_path}/nova </tmp/mysql.patch",
    #  require => [ [File['/tmp/mysql.patch']],[Package['patch', 'python-nova']]],
    #} ->

    cinder_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
  
  }

  if (defined(Exec['patch-cinder-rabbitmq']))
  {
    Exec['patch-cinder-rabbitmq']->Class['cinder::base']
    Exec['patch-cinder-rabbitmq']->Class['cinder::api']
    Exec['patch-cinder-rabbitmq']->Class['cinder::scheduler']
  }

  class { 'cinder::base':
    package_ensure => $::openstack_version['cinder'],
    rabbit_password => $rabbit_password,
    rabbit_hosts     => $rabbit_hosts,
    sql_connection  => $sql_connection,
    verbose         => $verbose,
  }
  class { 'cinder::api':
      package_ensure => $::openstack_version['cinder'],
      keystone_auth_host => $auth_host,
      keystone_password => $cinder_user_password,
      bind_host         => $bind_host,
  }   
   class { 'cinder::scheduler':
      package_ensure => $::openstack_version['cinder'],
      enabled        => true,
    }   
if $manage_volumes {
  if (defined(Exec['patch-cinder-rabbitmq']))
  {
    Exec['patch-cinder-rabbitmq']->Class['cinder::volume']
    Exec['patch-cinder-rabbitmq']->Class['cinder::volume::iscsi']
  }


    class { 'cinder::volume':
      package_ensure => $::openstack_version['cinder'],
      enabled        => true,
    }   

    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $bind_host,
      physical_volume  => $nv_physical_volume,
    } 
  }
}

  
