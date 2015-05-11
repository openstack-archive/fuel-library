# [use_syslog] Rather or not service should log to syslog. Optional. Defaults to false.

# [syslog_log_facility] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [ceilometer] true if we use ceilometer

class openstack::cinder(
  $sql_connection,
  $cinder_user_password,
  $glance_api_servers,
  $queue_provider         = 'rabbitmq',
  $amqp_hosts             = '127.0.0.1:5672',
  $amqp_user              = 'nova',
  $amqp_password          = 'rabbit_pw',
  $rabbit_ha_queues       = false,
  $volume_group           = 'cinder-volumes',
  $physical_volume        = undef,
  $manage_volumes         = false,
  $iser                   = false,
  $enabled                = true,
  $enable_volumes         = true,
  $purge_cinder_config    = true,
  $auth_host              = '127.0.0.1',
  $bind_host              = '0.0.0.0',
  $iscsi_bind_host        = '0.0.0.0',
  $use_syslog             = false,
  $syslog_log_facility    = 'LOG_LOCAL3',
  $cinder_rate_limits     = undef,
  $verbose                = false,
  $debug                  = false,
  $idle_timeout           = '3600',
  $max_pool_size          = '10',
  $max_overflow           = '30',
  $max_retries            = '-1',
  $keystone_enabled       = true,
  $keystone_tenant        = 'services',
  $keystone_auth_port     = '35357',
  $keystone_auth_protocol = 'http',
  $keystone_user          = 'cinder',
  $ceilometer             = false,
  $vmware_host_ip         = '10.10.10.10',
  $vmware_host_username   = 'administrator@vsphere.local',
  $vmware_host_password   = 'password',
  $rbd_pool               = 'volumes',
  $rbd_user               = 'volumes',
  $rbd_secret_uuid        = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
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


  class {'cinder::glance':
    glance_api_servers => $glance_api_servers,
    # Glance API v2 is required for Ceph RBD backend
    glance_api_version => '2',
  }

  if $queue_provider == 'rabbitmq' and $rabbit_ha_queues {
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
    Cinder_config['DEFAULT/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
  }

  case $queue_provider {
    'rabbitmq': {
      if $rabbit_ha_queues {
        if !is_array($amqp_hosts) {
          $rabbit_hosts_real = split($amqp_hosts, ',')
        } else {
          $rabbit_hosts_real = $amqp_hosts
        }
        # ::cinder module accepts rabbit_host and rabbit_port and then
        # makes "rabbit_host:rabbit_port" from it. So we need to split
        # our aqmp_hosts or provide defaults
        $rabbit_host_array = ['127.0.0.1', '5672']
      }
      else {
        $rabbit_hosts_real = false
        # ::cinder module accepts rabbit_host and rabbit_port and then
        # makes "rabbit_host:rabbit_port" from it. So we need to split
        # our aqmp_hosts or provide defaults
        $rabbit_host_array = split($amqp_hosts, ':')
      }
      class { '::cinder':
        package_ensure        => $::openstack_version['cinder'],
        rpc_backend           => 'cinder.openstack.common.rpc.impl_kombu',
        rabbit_host           => $rabbit_host_array[0],
        rabbit_port           => $rabbit_host_array[1],
        rabbit_hosts          => $rabbit_hosts_real,
        rabbit_userid         => $amqp_user,
        rabbit_password       => $amqp_password,
        rabbit_virtual_host   => $rabbit_virtual_host,
        database_connection   => $sql_connection,
        verbose               => $verbose,
        use_syslog            => $use_syslog,
        log_facility          => $syslog_log_facility,
        debug                 => $debug,
        database_idle_timeout => $idle_timeout,
        control_exchange      => 'cinder',
      }
      cinder_config {
        'DEFAULT/kombu_reconnect_delay': value => '5.0';
      }
    }
    'qpid': {
      $rpc_backend = 'cinder.openstack.common.rpc.impl_qpid'
      cinder_config {
        'DEFAULT/qpid_hosts':    value => $amqp_hosts;
        'DEFAULT/qpid_username': value => $amqp_user;
        'DEFAULT/qpid_password': value => $amqp_password;
      }
    }
  }

  if ($bind_host) {
    class { 'cinder::api':
      keystone_enabled   => $keystone_enabled,
      package_ensure     => $::openstack_version['cinder'],
      keystone_auth_host => $auth_host,
      keystone_password  => $cinder_user_password,
      bind_host          => $bind_host,
      ratelimits         => $cinder_rate_limits
    }

    class { 'cinder::scheduler':
      package_ensure => $::openstack_version['cinder'],
      enabled        => true,
    }
  }

  if $manage_volumes {
    ####### Disable upstart startup on install #######
    #NOTE(bogdando) ceph::backends::rbd creates override file as well
    if($::operatingsystem == 'Ubuntu' and $manage_volumes != 'ceph') {
      tweaks::ubuntu_service_override { 'cinder-volume':
        package_name => 'cinder-volume',
      }
    }

    class { 'cinder::volume':
      package_ensure => $::openstack_version['cinder'],
      enabled        => $enable_volumes,
    }

    case $manage_volumes {
      true, 'iscsi': {
        if ($physical_volume) {
          class { 'lvm':
            vg     => $volume_group,
            pv     => $physical_volume,
            before => Service['cinder-volume'],
          }
        }
        class { 'cinder::volume::iscsi':
          iscsi_ip_address => $iscsi_bind_host,
          volume_group     => $volume_group,
        }
        class { 'mellanox_openstack::cinder':
          iser            => $iser,
          iser_ip_address => $iscsi_bind_host,
        }
      }
      'ceph': {
        if defined(Class['::ceph']) {
          Ceph::Pool<| title == $::ceph::cinder_pool |> ->
          Class['cinder::volume::rbd']
        }

        class { 'cinder::volume::rbd':
          rbd_pool        => $rbd_pool,
          rbd_user        => $rbd_user,
          rbd_secret_uuid => $rbd_secret_uuid,
        }

        class { 'cinder::backup':
          enabled => true,
        }

        class { 'cinder::backup::ceph':
          backup_ceph_user => 'backups',
          backup_ceph_pool => 'backups',
        }
      }
    }
  }

  if $use_syslog {
    cinder_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  # additional cinder configuration
  cinder_config {
    'database/max_pool_size': value => $max_pool_size;
    'database/max_retries':   value => $max_retries;
    'database/max_overflow':  value => $max_overflow;
  }

  if $keystone_enabled {
    cinder_config {
      'keystone_authtoken/auth_protocol':     value => $keystone_auth_protocol;
      'keystone_authtoken/auth_host':         value => $auth_host;
      'keystone_authtoken/auth_port':         value => $keystone_auth_port;
      'keystone_authtoken/admin_tenant_name': value => $keystone_tenant;
      'keystone_authtoken/admin_user':        value => $keystone_user;
      'keystone_authtoken/admin_password':    value => $cinder_user_password;
      'keystone_authtoken/signing_dir':       value => '/tmp/keystone-signing-cinder';
      'keystone_authtoken/signing_dirname':   value => '/tmp/keystone-signing-cinder';
    }
  }

  if $ceilometer {
    class { "cinder::ceilometer": }
  }
}
