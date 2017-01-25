class openstack_tasks::ceilometer::compute {

  notice('MODULAR: ceilometer/compute.pp')

  $use_syslog               = hiera('use_syslog', true)
  $use_stderr               = hiera('use_stderr', false)
  $syslog_log_facility      = hiera('syslog_log_facility_ceilometer', 'LOG_LOCAL0')
  $rabbit_hash              = hiera_hash('rabbit')
  $management_vip           = hiera('management_vip')
  $service_endpoint         = hiera('service_endpoint', $management_vip)

  $default_ceilometer_hash = {
    'enabled'                    => false,
    'db_password'                => 'ceilometer',
    'user_password'              => 'ceilometer',
    'metering_secret'            => 'ceilometer',
    'http_timeout'               => '600',
    'event_time_to_live'         => '604800',
    'metering_time_to_live'      => '604800',
  }

  $region                     = hiera('region', 'RegionOne')
  $ceilometer_hash            = hiera_hash('ceilometer', $default_ceilometer_hash)
  $ceilometer_region          = pick($ceilometer_hash['region'], $region)
  $ceilometer_enabled         = $ceilometer_hash['enabled']
  $transport_url              = hiera('transport_url','rabbit://guest:password@127.0.0.1:5672/')
  $kombu_compression          = hiera('kombu_compression', $::os_service_default)
  $ceilometer_metering_secret = $ceilometer_hash['metering_secret']
  $debug                      = pick($ceilometer_hash['debug'], hiera('debug', false))
  $ssl_hash                   = hiera_hash('use_ssl', {})

  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint])

  $admin_auth_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_endpoint        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint])

  $keystone_identity_uri      = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/"
  $keystone_auth_uri          = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"

  $rabbit_heartbeat_timeout_threshold = pick($ceilometer_hash['rabbit_heartbeat_timeout_threshold'], $rabbit_hash['heartbeat_timeout_threshold'], 60)
  $rabbit_heartbeat_rate              = pick($ceilometer_hash['rabbit_heartbeat_rate'], $rabbit_hash['rabbit_heartbeat_rate'], 2)

  if ($ceilometer_enabled) {

    class { '::ceilometer':
      http_timeout                       => $ceilometer_hash['http_timeout'],
      event_time_to_live                 => $ceilometer_hash['event_time_to_live'],
      metering_time_to_live              => $ceilometer_hash['metering_time_to_live'],
      default_transport_url              => $transport_url,
      metering_secret                    => $ceilometer_metering_secret,
      debug                              => $debug,
      use_syslog                         => $use_syslog,
      use_stderr                         => $use_stderr,
      log_facility                       => $syslog_log_facility,
      kombu_compression                  => $kombu_compression,
      rabbit_heartbeat_timeout_threshold => $rabbit_heartbeat_timeout_threshold,
      rabbit_heartbeat_rate              => $rabbit_heartbeat_rate,
    }

    class { '::ceilometer::agent::auth':
      auth_url           => $keystone_auth_uri,
      auth_password      => $ceilometer_hash['user_password'],
      auth_region        => $ceilometer_region,
      auth_tenant_name   => $ceilometer_hash['tenant'],
      auth_user          => $ceilometer_hash['user'],
      auth_endpoint_type => 'internalURL',
    }

    class { '::ceilometer::client': }

    if ($use_syslog) {
      ceilometer_config {
        'DEFAULT/use_syslog_rfc_format': value => true;
      }
    }

    if $::operatingsystem == 'Ubuntu' {
      User<| name == 'ceilometer' |> {
        groups => ['nova'],
      }
    }

    class { '::ceilometer::agent::polling':
      central_namespace => false,
      ipmi_namespace    => false
    }
  }
}
