# [use_syslog] Rather or not service should log to syslog. Optional. Defaults to false.
# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [syslog_log_level] logging level for non verbose and non debug mode. Optional.

class openstack::cinder(
  $sql_connection,
  $cinder_user_password,
  $glance_api_servers,
  $queue_provider         = 'rabbitmq',
  $amqp_hosts             = '127.0.0.1',
  $amqp_user              = 'nova',
  $amqp_password          = 'rabbit_pw',
  $rabbit_ha_queues       = false,
  $volume_group           = 'cinder-volumes',
  $physical_volume        = undef,
  $manage_volumes         = false,
  $enabled                = true,
  $purge_cinder_config    = true,
  $auth_host              = '127.0.0.1',
  $bind_host              = '0.0.0.0',
  $iscsi_bind_host        = '0.0.0.0',
  $use_syslog             = false,
  $syslog_log_facility    = 'LOG_LOCAL3',
  $syslog_log_level       = 'WARNING',
  $cinder_rate_limits     = undef,
  $verbose                = false,
  $debug                  = false,
  $idle_timeout           = '3600',
  $max_pool_size          = '10',
  $max_overflow           = '30',
  $max_retries            = '-1',
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

  if $queue_provider == 'rabbitmq' and $rabbit_ha_queues {
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
    cinder_config { 'DEFAULT/rabbit_ha_queues': value => 'True' }
  }

  class { 'cinder::base':
    package_ensure      => $::openstack_version['cinder'],
    queue_provider      => $queue_provider,
    amqp_hosts          => $amqp_hosts,
    amqp_user           => $amqp_user,
    amqp_password       => $amqp_password,
    sql_connection      => $sql_connection,
    verbose             => $verbose,
    use_syslog          => $use_syslog,
    syslog_log_facility => $syslog_log_facility,
    syslog_log_level    => $syslog_log_level,
    debug               => $debug,
    max_retries         => $max_retries,
    max_pool_size       => $max_pool_size,
    max_overflow        => $max_overflow,
    idle_timeout        => $idle_timeout,
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
    case $manage_volumes {
      true, 'iscsi': {
        class { 'cinder::volume::iscsi':
          iscsi_ip_address => $iscsi_bind_host,
          physical_volume  => $physical_volume,
          volume_group     => $volume_group,
        }
      }
      'ceph': {
        class {'cinder::volume::ceph': }
      }
    }
  }
}

