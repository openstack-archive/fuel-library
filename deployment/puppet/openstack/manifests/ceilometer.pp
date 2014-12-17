#
# == Class: openstack::ceilometer
#
# Installs and configures Ceilometer
#

class openstack::ceilometer (
  $keystone_password   = 'ceilometer_pass',
  $metering_secret     = 'ceilometer',
  $verbose             =  false,
  $use_syslog          =  false,
  $syslog_log_facility = 'LOG_LOCAL0',
  $debug               =  false,
  $db_type             = 'mysql',
  $db_host             = 'localhost',
  $db_user             = 'ceilometer',
  $db_password         = 'ceilometer_pass',
  $db_dbname           = 'ceilometer',
  $swift_rados_backend = false,
  $mongo_replicaset    = false,
  $amqp_hosts          = '127.0.0.1',
  $amqp_user           = 'guest',
  $amqp_password       = 'rabbit_pw',
  $rabbit_ha_queues    = false,
  $keystone_host       = '127.0.0.1',
  $host                = '0.0.0.0',
  $port                = '8777',
  $on_controller       = false,
  $on_compute          = false,
  $ha_mode             = false,
  $primary_controller  = false,
  $use_neutron         = false,
  $swift               = false,
) {

  # Add the base ceilometer class & parameters
  # This class is required by ceilometer agents & api classes
  # The metering_secret parameter is mandatory
  class { '::ceilometer':
    package_ensure      => $::openstack_version['ceilometer'],
    rabbit_hosts        => split($amqp_hosts, ','),
    rabbit_userid       => $amqp_user,
    rabbit_password     => $amqp_password,
    metering_secret     => $metering_secret,
    verbose             => $verbose,
    debug               => $debug,
    use_syslog          => $use_syslog,
    log_facility        => $syslog_log_facility,
  }

  # Configure authentication for agents
  class { '::ceilometer::agent::auth':
    auth_url      => "http://${keystone_host}:5000/v2.0",
    auth_password => $keystone_password,
  }

  class { '::ceilometer::client': }

  if ($on_controller) {
    # Configure the ceilometer database
    # Only needed if ceilometer::agent::central or ceilometer::api are declared

    if ( $db_type == 'mysql' ) {
      $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}?read_timeout=60"
    } else {
      if ( !$mongo_replicaset ) {
        $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
      } else {
        # added for future use with replicaset params
        $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
      }
    }

    class { '::ceilometer::db':
      database_connection => $current_database_connection,
    }

    # Install the ceilometer-api service
    # The keystone_password parameter is mandatory
    class { '::ceilometer::api':
      keystone_host     => $keystone_host,
      keystone_password => $keystone_password,
      host              => $host,
      port              => $port,
    }

    class { '::ceilometer::collector': }

    class { '::ceilometer::agent::central': }

    class { '::ceilometer::alarm::evaluator':
      evaluation_interval => 60,
    }

    class { '::ceilometer::alarm::notifier': }

    class { '::ceilometer::agent::notification': }

    if $use_neutron {
      neutron_config { 'DEFAULT/notification_driver': value => 'messaging' }
    }

    if $swift {
      class {'::openstack::swift::notify::ceilometer':
        enable_ceilometer => true,
      }
    }

    if $ha_mode {
      $ceilometer_agent_res_name = "p_${::ceilometer::params::agent_central_service_name}"

      Package['pacemaker'] -> File['ceilometer-agent-central-ocf']
      Package['ceilometer-common'] -> File['ceilometer-agent-central-ocf']
      Package['ceilometer-agent-central'] -> File['ceilometer-agent-central-ocf']

      file {'ceilometer-agent-central-ocf':
        path   => '/usr/lib/ocf/resource.d/mirantis/ceilometer-agent-central',
        mode   => '0755',
        owner  => root,
        group  => root,
        source => 'puppet:///modules/ceilometer/ocf/ceilometer-agent-central',
      }

      if $primary_controller {
        cs_resource { $ceilometer_agent_res_name:
          ensure          => present,
          primitive_class => 'ocf',
          provided_by     => 'mirantis',
          primitive_type  => 'ceilometer-agent-central',
          metadata        => { 'target-role' => 'stopped', 'resource-stickiness' => '1' },
          parameters      => { 'user' => 'ceilometer' },
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
        File['ceilometer-agent-central-ocf'] -> Cs_resource[$ceilometer_agent_res_name] -> Service['ceilometer-agent-central']
      } else {
        File['ceilometer-agent-central-ocf'] -> Service['ceilometer-agent-central']
      }
    } else {
      Package['ceilometer-common'] -> Service['ceilometer-agent-central']
      Package['ceilometer-agent-central'] -> Service['ceilometer-agent-central']
    }
  }

  if $ha_mode {

    $ceilometer_alarm_res_name = "p_${::ceilometer::params::alarm_evaluator_service_name}"

    Package['ceilometer-common'] -> File['ceilometer-alarm-evaluator-ocf']
    Package[$::ceilometer::params::alarm_package_name] -> File['ceilometer-alarm-evaluator-ocf']
    Package['pacemaker'] -> File['ceilometer-alarm-evaluator-ocf']
    file {'ceilometer-alarm-evaluator-ocf':
      path   => '/usr/lib/ocf/resource.d/mirantis/ceilometer-alarm-evaluator',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => 'puppet:///modules/ceilometer/ocf/ceilometer-alarm-evaluator',
    }

    if $primary_controller {
      cs_resource { $ceilometer_alarm_res_name:
        ensure          => present,
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'ceilometer-alarm-evaluator',
        metadata        => { 'target-role' => 'stopped' },
        parameters      => { 'user' => 'ceilometer' },
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
      File['ceilometer-alarm-evaluator-ocf'] -> Cs_resource[$ceilometer_alarm_res_name] -> Service['ceilometer-alarm-evaluator']
    }
    File['ceilometer-alarm-evaluator-ocf'] -> Service['ceilometer-alarm-evaluator']
  }

  if ($swift_rados_backend) {
    ceilometer_config {
       'DEFAULT/swift_rados_backend'    : value => $swift_rados_backend;
    }
  }

  if ($use_syslog) {
    ceilometer_config {
       'DEFAULT/use_syslog_rfc_format': value => true;
    }
  }

  Package<| title == $::ceilometer::params::alarm_package or
    title == 'ceilometer-common'|> ~>
  Service<| title == 'ceilometer-alarm-evaluator'|>

  if !defined(Service['ceilometer-alarm-evaluator']) {
    notify{ "Module ${module_name} cannot notify service ceilometer-alarm-evaluator on packages update": }
  }

  if ($on_compute) {
    # Install compute agent
    class { 'ceilometer::agent::compute':
      enabled => true,
    }
    ceilometer_config { 'service_credentials/os_endpoint_type': value => 'internalURL'} ->
    Service<| title == 'ceilometer-agent-compute'|>
  }
}
