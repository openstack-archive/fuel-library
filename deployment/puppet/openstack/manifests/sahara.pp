#
# == Class: openstack::sahara
#
# Installs and configures Sahara
#

class openstack::sahara (
  $sahara_api_host            = '127.0.0.1',
  $sahara_db_password         = 'sahara-pass',
  $sahara_db_host             = '127.0.0.1',
  $sahara_keystone_host       = '127.0.0.1',
  $sahara_keystone_user       = 'sahara',
  $sahara_keystone_password   = 'sahara-pass',
  $sahara_keystone_tenant     = 'services',
  $use_neutron                = 'false',
  $syslog_log_facility_sahara = 'LOG_LOCAL0',
  $debug                      = false,
  $verbose                    = false,
  $use_syslog                 = false,
  $rpc_backend                = 'rabbit',
  $enable_notifications       = false,
  $amqp_password              = 'rabbit_pw',
  $amqp_user                  = 'nova',
  $amqp_port                  = '5672',
  $amqp_hosts                 = '127.0.0.1',
  $rabbit_ha_queues           = false,
  $ha_mode                    = false,
) {

  class { '::sahara':
      sahara_api_host            => $sahara_api_host,
      sahara_db_password         => $sahara_db_password,
      sahara_db_host             => $sahara_db_host,
      sahara_keystone_host       => $sahara_keystone_host,
      sahara_keystone_user       => $sahara_keystone_user,
      sahara_keystone_password   => $sahara_keystone_password,
      sahara_keystone_tenant     => $sahara_keystone_tenant,
      sahara_auth_uri            => "http://${sahara_keystone_host}:5000/v2.0/",
      sahara_identity_uri        => "http://${sahara_keystone_host}:35357/",
      use_neutron                => $use_neutron,
      syslog_log_facility_sahara => $syslog_log_facility_sahara,
      debug                      => $debug,
      verbose                    => $verbose,
      use_syslog                 => $use_syslog,
      enable_notifications       => $enable_notifications,
      rpc_backend                => $rpc_backend,
      amqp_password              => $amqp_password,
      amqp_user                  => $amqp_user,
      amqp_port                  => $rabbitmq_bind_port,
      amqp_hosts                 => $amqp_hosts,
      rabbit_ha_queues           => $rabbit_ha_queues,
  }

  if $ha_mode {
      $sahara_all_res_name = "p_${::sahara::params::sahara_service_name}"

      Package['pacemaker'] -> File['sahara-all-ocf']
      Package['sahara'] -> File['sahara-all-ocf']

      file {'sahara-all-ocf':
        path   => '/usr/lib/ocf/resource.d/mirantis/sahara-all',
        mode   => '0755',
        owner  => root,
        group  => root,
        source => 'puppet:///modules/sahara/ocf/sahara-all',
      }

      if $primary_controller {
        cs_resource { $sahara_all_res_name:
          ensure          => present,
          primitive_class => 'ocf',
          provided_by     => 'mirantis',
          primitive_type  => 'sahara-all',
          metadata        => { 'target-role' => 'stopped', 'resource-stickiness' => '1' },
          parameters      => { 'user' => 'sahara' },
          operations      => {
            'monitor' => {
              'interval' => '20',
              'timeout'  => '30'
            },
            'start'   => {
              'timeout'  => '360'
            },
            'stop'    => {
              'timeout'  => '360'
            },
          },
        }
        File['sahara-all-ocf'] -> Cs_resource[$sahara_all_res_name] -> Service['sahara-api']
      } else {
        Package['sahara'] -> Service['sahara-api']
      }
  }

}
