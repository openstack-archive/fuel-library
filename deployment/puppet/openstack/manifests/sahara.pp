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
    $csr_metadata    = undef
    $csr_ms_metadata = { 'interleave' => 'true' }
    $sahara_package  = $::sahara::params::sahara_package_name

    cluster::corosync::cs_service {'sahara':
      ocf_script       => 'sahara-all',
      csr_parameters   => undef,
      csr_metadata     => $csr_metadata,
      csr_complex_type => 'clone',
      csr_ms_metadata  => $csr_ms_metadata,
      csr_mon_intr     => '20',
      csr_mon_timeout  => '10',
      csr_timeout      => '60',
      service_name     => $::sahara::params::sahara_service_name,
      package_name     => $sahara_package,
      service_title    => 'sahara-api',
      primary          => $primary_controller,
      hasrestart       => true,
    }
  }

}
