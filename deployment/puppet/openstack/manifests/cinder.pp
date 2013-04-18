class openstack::cinder(
  $sql_connection,
  $cinder_user_password,
  $rabbit_password,
  $rabbit_host     = false,
  $rabbit_nodes    = ['127.0.0.1'],
  $rabbit_ha_virtual_ip = false,
  $volume_group    = 'cinder-volumes',
  $physical_volume = undef,
  $manage_volumes  = false,
  $enabled         = true,
  $purge_cinder_config = true,
  $auth_host          = '127.0.0.1',
  $bind_host          = '0.0.0.0',
  $iscsi_bind_host    = '0.0.0.0',
  $use_syslog         = false,
  $cinder_rate_limits = undef
) {
  include cinder::params
  #  if ($purge_cinder_config) {
  # resources { 'cinder_config':
  #   purge => true,
  # }
  #}
  if $rabbit_nodes and !$rabbit_ha_virtual_ip {
    $rabbit_hosts = inline_template("<%= @rabbit_nodes.map {|x| x + ':5672'}.join ',' %>")
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
    cinder_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
  }
  elsif $rabbit_ha_virtual_ip {
    $rabbit_hosts = "${rabbit_ha_virtual_ip}:5672"
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
    cinder_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
  }

  class { 'cinder::base':
    package_ensure  => $::openstack_version['cinder'],
    rabbit_password => $rabbit_password,
    rabbit_hosts    => $rabbit_hosts,
    sql_connection  => $sql_connection,
    verbose         => $verbose,
    use_syslog => $use_syslog
  }
  if ($bind_host) {
    class { 'cinder::api':
      package_ensure     => $::openstack_version['cinder'],
      keystone_auth_host => $auth_host,
      keystone_password  => $cinder_user_password,
      bind_host          => $bind_host,
      cinder_rate_limits => $cinder_rate_limits
    }

    class { 'cinder::scheduler':
      package_ensure => $::openstack_version['cinder'],
      enabled        => true,
    }
  }
  if $manage_volumes {
    class { 'cinder::volume':
      package_ensure => $::openstack_version['cinder'],
      enabled        => true,
    }
    class { 'cinder::volume::iscsi':
      iscsi_ip_address => $iscsi_bind_host,
      physical_volume  => $physical_volume,
      volume_group     => $volume_group,
    }
  }
}

