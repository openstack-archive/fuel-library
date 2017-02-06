# [*use_syslog*] Rather or not service should log to syslog. Optional. Defaults to false.
# [*use_stderr*] Rather or not service should send output to stderr. Optional. Defaults to true.

# [*syslog_log_facility*] Facility for syslog, if used. Optional. Note: duplicating conf option
#       wouldn't have been used, but more powerfull rsyslog features managed via conf template instead
# [*notification_driver*] The driver(s) name to handle notifications. Defaults to undef.

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
  $volume_backend_name    = 'DEFAULT',
  $manage_volumes         = false,
  $iser                   = false,
  $enabled                = true,
  $enable_volumes         = true,
  $purge_cinder_config    = true,
  $bind_host              = '0.0.0.0',
  $iscsi_bind_host        = '0.0.0.0',
  $use_syslog             = false,
  $use_stderr             = true,
  $syslog_log_facility    = 'LOG_LOCAL3',
  $cinder_rate_limits     = undef,
  $primary_controller     = false,
  $debug                  = false,
  $default_log_levels     = undef,
  $idle_timeout           = '3600',
  $max_pool_size          = '10',
  $max_overflow           = '30',
  $max_retries            = '-1',
  $keystone_enabled       = true,
  $keystone_tenant        = 'services',
  $auth_uri               = false,
  $privileged_auth_uri    = false,
  $identity_uri           = false,
  $keystone_user          = 'cinder',
  $region                 = 'RegionOne',
  $notification_driver    = undef,
  $service_workers        = $::os_workers,
  $rbd_pool               = 'volumes',
  $rbd_user               = 'volumes',
  $rbd_secret_uuid        = 'a5d0dd94-57c4-ae55-ffe0-7e3732a24455',
  $swift_url              = false,
  $openstack_version      = {},
) {

  warning('openstack::cinder is deprecated in mitaka and will be removed in Newton')
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

  #NOTE(mattymo): Remove keymgr_encryption_auth_url after LP#1516085 is fixed
  if $identity_uri {
    $keymgr_encryption_auth_url = "${identity_uri}/v3"
  } else {
    $keymgr_encryption_auth_url = $::os_service_default
  }

  if $queue_provider == 'rabbitmq' and $rabbit_ha_queues {
    Cinder_config['oslo_messaging_rabbit/rabbit_ha_queues']->Service<| title == 'cinder-api'|>
    Cinder_config['oslo_messaging_rabbit/rabbit_ha_queues']->Service<| title == 'cinder-volume' |>
    Cinder_config['oslo_messaging_rabbit/rabbit_ha_queues']->Service<| title == 'cinder-scheduler' |>
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
        $rabbit_host_array = [undef,undef]
      } else {
        $rabbit_hosts_real = false
        # ::cinder module accepts rabbit_host and rabbit_port and then
        # makes "rabbit_host:rabbit_port" from it. So we need to split
        # our aqmp_hosts or provide defaults
        $rabbit_host_array = split($amqp_hosts, ':')
      }
      class { '::cinder':
        package_ensure         => $openstack_version['cinder'],
        rpc_backend            => 'cinder.openstack.common.rpc.impl_kombu',
        rabbit_host            => $rabbit_host_array[0],
        rabbit_port            => $rabbit_host_array[1],
        rabbit_hosts           => $rabbit_hosts_real,
        rabbit_userid          => $amqp_user,
        rabbit_password        => $amqp_password,
        rabbit_virtual_host    => $rabbit_virtual_host,
        database_connection    => $sql_connection,
        use_syslog             => $use_syslog,
        use_stderr             => $use_stderr,
        log_facility           => $syslog_log_facility,
        debug                  => $debug,
        database_idle_timeout  => $idle_timeout,
        database_max_pool_size => $max_pool_size,
        database_max_retries   => $max_retries,
        database_max_overflow  => $max_overflow,
        control_exchange       => 'cinder',
        rabbit_ha_queues       => $rabbit_ha_queues,
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
      keystone_enabled             => $keystone_enabled,
      package_ensure               => $openstack_version['cinder'],
      auth_uri                     => $auth_uri,
      identity_uri                 => $identity_uri,
      keystone_user                => $keystone_user,
      keystone_tenant              => $keystone_tenant,
      keystone_password            => $cinder_user_password,
      os_region_name               => $region,
      bind_host                    => $bind_host,
      ratelimits                   => $cinder_rate_limits,
      service_workers              => $service_workers,
      privileged_user              => true,
      os_privileged_user_password  => $cinder_user_password,
      os_privileged_user_tenant    => $keystone_tenant,
      os_privileged_user_auth_url  => $privileged_auth_uri,
      os_privileged_user_name      => $keystone_user,
      keymgr_encryption_auth_url   => $keymgr_encryption_auth_url,
      nova_catalog_admin_info      => 'compute:nova:adminURL',
      nova_catalog_info            => 'compute:nova:internalURL',
      sync_db                      => $primary_controller,
    }

    class { 'cinder::scheduler':
      package_ensure => $openstack_version['cinder'],
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

    if($::operatingsystem == 'Ubuntu' and $manage_volumes == 'ceph') {
      tweaks::ubuntu_service_override { "tgtd-service":
        package_name => "$::cinder::params::tgt_package_name",
        service_name => "$::cinder::params::tgt_service_name",
      }
      package { "$::cinder::params::tgt_package_name":
        ensure   => installed,
        name     => $::cinder::params::tgt_package_name,
        before   => Class['cinder::volume'],
      }
      service { "$::cinder::params::tgt_service_name":
        enable   => false,
        ensure   => stopped,
      }
    }

    class { 'cinder::volume':
      package_ensure => $openstack_version['cinder'],
      enabled        => $enable_volumes,
    }

    case $manage_volumes {
      true, 'iscsi': {
        cinder::backend::iscsi { 'DEFAULT':
          iscsi_ip_address    => $iscsi_bind_host,
          volume_group        => $volume_group,
          volume_backend_name => $volume_backend_name,
        }

        class { 'cinder::backup':
          enabled => true,
        }
        tweaks::ubuntu_service_override { 'cinder-backup':
          package_name => 'cinder-backup',
        }

        class { 'cinder::backup::swift':
          backup_swift_url      => "${swift_url}/v1/AUTH_",
          backup_swift_auth_url => "${auth_uri}/v2.0",
        }
      }
      'ceph': {
        if defined(Class['::ceph']) {
          Ceph::Pool<| title == $::ceph::cinder_pool |> ->
          Cinder::Backend::Rbd['DEFAULT']
        }

        cinder::backend::rbd { 'DEFAULT':
          rbd_pool            => $rbd_pool,
          rbd_user            => $rbd_user,
          rbd_secret_uuid     => $rbd_secret_uuid,
          volume_backend_name => $volume_backend_name,
        }

        class { 'cinder::backup':
          enabled => true,
        }
        tweaks::ubuntu_service_override { 'cinder-backup':
          package_name => 'cinder-backup',
        }

        class { 'cinder::backup::ceph':
          backup_ceph_user => 'backups',
          backup_ceph_pool => 'backups',
        }
      }
      'fake': {
        class { 'cinder::config':
          cinder_config => {
            'DEFAULT/iscsi_ip_address'    => { value => $iscsi_bind_host },
            'DEFAULT/iscsi_helper'        => { value => 'fake' },
            'DEFAULT/iscsi_protocol'      => { value => 'iscsi' },
            'DEFAULT/volume_backend_name' => { value => $volume_backend_name },
            'DEFAULT/volume_driver'       => { value => 'cinder.volume.drivers.block_device.BlockDeviceDriver' },
            'DEFAULT/volume_group'        => { value => 'cinder' },
            'DEFAULT/volume_dir'          => { value => '/var/lib/cinder/volumes' },
            'DEFAULT/available_devices'   => { value => $physical_volume },
          }
        }
      }
    }
  }

  if $use_syslog {
    cinder_config {
      'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  if $notification_driver {
    class { 'cinder::ceilometer':
      notification_driver => $notification_driver
    }
  }
}
