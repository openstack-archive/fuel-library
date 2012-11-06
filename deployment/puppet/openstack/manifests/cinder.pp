class openstack::cinder(
  $sql_connection,
  $rabbit_password,
  $rabbit_host     = false,
  $rabbit_nodes    = ['127.0.0.1']
  $volume_group    = 'cinder-volumes',
  $physical_volume = undef,
  $manage_volumes  = false,
  $enabled         = true,
  $purge_cinder_config = true,
  $auth_host          = '127.0.0.1',
  $bind_host          = '127.0.0.1',
) {

  if ($purge_nova_config) {
    resources { 'cinder_config':
      purge => true,
    }   
  }

  if $rabbit_nodes {
    $rabbit_hosts = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
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
  }   



if $manage_volumes {

    class { 'cinder::volume':
      package_ensure => $::openstack_version['cinder'],
      enabled        => true,
    }   

    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $internal_address,
      physical_volume  => $nv_physical_volume,
    } 
  }
}

  
