class osnailyfacter::ceilometer::compute {

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
    'alarm_history_time_to_live' => '604800',
  }

  $region                     = hiera('region', 'RegionOne')
  $ceilometer_hash            = hiera_hash('ceilometer', $default_ceilometer_hash)
  $ceilometer_region          = pick($ceilometer_hash['region'], $region)
  $ceilometer_enabled         = $ceilometer_hash['enabled']
  $amqp_password              = $rabbit_hash['password']
  $amqp_user                  = $rabbit_hash['user']
  $kombu_compression          = hiera('kombu_compression', '')
  $ceilometer_metering_secret = $ceilometer_hash['metering_secret']
  $verbose                    = pick($ceilometer_hash['verbose'], hiera('verbose', true))
  $debug                      = pick($ceilometer_hash['debug'], hiera('debug', false))
  $ssl_hash                   = hiera_hash('use_ssl', {})

  $internal_auth_protocol     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'protocol', 'http')
  $internal_auth_endpoint     = get_ssl_property($ssl_hash, {}, 'keystone', 'internal', 'hostname', [$service_endpoint])

  $admin_auth_protocol        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'protocol', 'http')
  $admin_auth_endpoint        = get_ssl_property($ssl_hash, {}, 'keystone', 'admin', 'hostname', [$service_endpoint])

  $keystone_identity_uri      = "${admin_auth_protocol}://${admin_auth_endpoint}:35357/"
  $keystone_auth_uri          = "${internal_auth_protocol}://${internal_auth_endpoint}:5000/"

  if ($ceilometer_enabled) {

    class { '::ceilometer':
      http_timeout               => $ceilometer_hash['http_timeout'],
      event_time_to_live         => $ceilometer_hash['event_time_to_live'],
      metering_time_to_live      => $ceilometer_hash['metering_time_to_live'],
      alarm_history_time_to_live => $ceilometer_hash['alarm_history_time_to_live'],
      rabbit_hosts               => split(hiera('amqp_hosts',''), ','),
      rabbit_userid              => $amqp_user,
      rabbit_password            => $amqp_password,
      metering_secret            => $ceilometer_metering_secret,
      verbose                    => $verbose,
      debug                      => $debug,
      use_syslog                 => $use_syslog,
      use_stderr                 => $use_stderr,
      log_facility               => $syslog_log_facility,
    }

    class { '::ceilometer::agent::auth':
      auth_url         => $keystone_auth_uri,
      auth_password    => $ceilometer_hash['user_password'],
      auth_region      => $ceilometer_region,
      auth_tenant_name => $ceilometer_hash['tenant'],
      auth_user        => $ceilometer_hash['user'],
    }

    class { '::ceilometer::client': }



    if ($use_syslog) {
      ceilometer_config {
        'DEFAULT/use_syslog_rfc_format': value => true;
      }
    }

    if $::operatingsystem == 'Ubuntu' and $::ceilometer::params::libvirt_group {
      # Our libvirt-bin deb package (1.2.9 version) creates 'libvirt' group on Ubuntu
      if (versioncmp($::libvirt_package_version, '1.2.9') >= 0) {
        User<| name == 'ceilometer' |> {
          groups => ['nova', 'libvirt'],
        }
      }
    }

    class { '::ceilometer::agent::polling':
      central_namespace => false,
      ipmi_namespace    => false
    }

    # TODO (iberezovskiy): remove this workaround in N when ceilometer module
    # will be switched to puppet-oslo usage for rabbit configuration
    if $kombu_compression in ['gzip','bz2'] {
      if !defined(Oslo::Messaging_rabbit['ceilometer_config']) and !defined(Ceilometer_config['oslo_messaging_rabbit/kombu_compression']) {
        ceilometer_config { 'oslo_messaging_rabbit/kombu_compression': value => $kombu_compression; }
      } else {
        Ceilometer_config<| title == 'oslo_messaging_rabbit/kombu_compression' |> { value => $kombu_compression }
      }
    }

  ceilometer_config { 'service_credentials/os_endpoint_type': value => 'internalURL'} ->
  Service<| title == 'ceilometer-polling'|>
  }

}
