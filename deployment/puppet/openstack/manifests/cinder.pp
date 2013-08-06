# [use_syslog] Rather or not service should log to syslog. Optional.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option 
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.

class openstack::cinder(
  $sql_connection,
  $cinder_user_password,
  $rabbit_password,
  $rabbit_host            = false,
  $rabbit_nodes           = ['127.0.0.1'],
  $rabbit_ha_virtual_ip   = false,
  $glance_api_servers,
  $volume_group           = 'cinder-volumes',
  $physical_volume        = undef,
  $manage_volumes         = false,
  $enabled                = true,
  $purge_cinder_config    = true,
  $auth_host              = '127.0.0.1',
  $bind_host              = '0.0.0.0',
  $iscsi_bind_host        = '0.0.0.0',
  $use_syslog             = false,
  $syslog_log_facility    = 'LOCAL3',
  $syslog_log_level = 'WARNING',
  $cinder_rate_limits     = undef,
  $verbose          = 'False',
  $debug             = 'False',
  $queue_provider  = 'rabbitmq',
  $qpid_password   = 'qpid_pw',
  $qpid_user       = 'nova',
  $qpid_nodes      = ['127.0.0.1'],
) {
  include cinder::params
  #  if ($purge_cinder_config) {
  # resources { 'cinder_config':
  #   purge => true,
  # }
  #}
  #  There are two assumptions - everyone should use keystone auth
  #  and we had glance_api_servers set globally in every mode except 
  #  single when service should authenticate itself against 
  #  localhost anyway.


  cinder_config { 'DEFAULT/auth_strategy': value => 'keystone' }
  cinder_config { 'DEFAULT/glance_api_servers': value => $glance_api_servers }
 
  case $queue_provider {
    "rabbitmq": {
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
    }
    'qpid': {
      $qpid_hosts = inline_template("<%= @qpid_nodes.map {|x| x + ':5672'}.join ',' %>")
    }
  }

  class { 'cinder::base':
    package_ensure  => $::openstack_version['cinder'],
    queue_provider  => $queue_provider,
    rabbit_password => $rabbit_password,
    rabbit_hosts    => $rabbit_hosts,
    qpid_password   => $qpid_password,
    qpid_userid     => $qpid_user,
    qpid_hosts      => $qpid_hosts,
    sql_connection  => $sql_connection,
    verbose         => $verbose,
    use_syslog      => $use_syslog,
    syslog_log_facility => $syslog_log_facility,
    syslog_log_level    => $syslog_log_level,
    debug           => $debug,
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

