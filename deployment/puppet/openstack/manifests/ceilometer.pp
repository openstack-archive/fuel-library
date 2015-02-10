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
  $mongo_replicaset    = undef,
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
  $ext_mongo           = false,
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

    if ( !$ext_mongo ) {
      if ( $db_type == 'mysql' ) {
        $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}?read_timeout=60"
      } else {
        if ( !$mongo_replicaset ) {
          $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
        } else {
          $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
          ceilometer_config {
            'database/mongodb_replica_set' : value => $mongo_replicaset;
          }
        }
      }
    } else {
       $current_database_connection = "${db_type}://${db_user}:${db_password}@${db_host}/${db_dbname}"
       if $mongo_replicaset {
         ceilometer_config {
            'database/mongodb_replica_set' : value => $mongo_replicaset;
          }
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

    class { '::ceilometer::agent::central':
      enabled => !$ha_mode,
    }

    class { '::ceilometer::alarm::evaluator':
      enabled             => !$ha_mode,
      evaluation_interval => 60,
    }

    class { '::ceilometer::alarm::notifier': }

    class { '::ceilometer::agent::notification':
      store_events => true,
    }

    if $use_neutron {
      neutron_config { 'DEFAULT/notification_driver': value => 'messaging' }
    }

    if $swift {
      class {'::openstack::swift::notify::ceilometer':
        enable_ceilometer => true,
      }
    }

    if $ha_mode {

      tweaks::ubuntu_service_override { "$::ceilometer::params::agent_central_service_name":
        package_name => $::ceilometer::params::agent_central_package_name,
      }

      Package['pacemaker'] -> Cluster::Corosync::Cs_service['ceilometer_agent_central']
      Package['ceilometer-common'] -> Cluster::Corosync::Cs_service['ceilometer_agent_central']
      Package[$::ceilometer::params::agent_central_package_name] -> Cluster::Corosync::Cs_service['ceilometer_agent_central']

      cluster::corosync::cs_service { 'ceilometer_agent_central':
        ocf_script        => 'ceilometer-agent-central',
        service_name      => $::ceilometer::params::agent_central_service_name,
        csr_parameters    => { 'user' => 'ceilometer' },
        csr_metadata      => { 'resource-stickiness' => '1' },
        csr_mon_intr      => 20,
        csr_mon_timeout   => 30,
        csr_timeout       => 360,
        service_title     => 'ceilometer-agent-central',
        hasrestart        => false,
      }
    } 
    else {
      Package['ceilometer-common'] -> Service['ceilometer-agent-central']
      Package['ceilometer-agent-central'] -> Service['ceilometer-agent-central']
    }
  }

  if $ha_mode {

    case $::osfamily {
      'RedHat': {
        $alarm_package = $::ceilometer::params::alarm_package_name[0]
      }
      'Debian': {
        $alarm_package = $::ceilometer::params::alarm_package_name[1]
      }
    }

    tweaks::ubuntu_service_override { "$::ceilometer::params::alarm_evaluator_service_name":
      package_name => $alarm_package,
    }

    Package['pacemaker'] -> Cluster::Corosync::Cs_service['ceilometer_alarm_evaluator']
    Package['ceilometer-common'] -> Cluster::Corosync::Cs_service['ceilometer_alarm_evaluator']
    Package[$alarm_package] -> Cluster::Corosync::Cs_service['ceilometer_alarm_evaluator']

    cluster::corosync::cs_service { 'ceilometer_alarm_evaluator':
      ocf_script        => 'ceilometer-alarm-evaluator',
      service_name      => $::ceilometer::params::alarm_evaluator_service_name,
      csr_parameters    => { 'user' => 'ceilometer' },
      csr_metadata      => { 'resource-stickiness' => '1' },
      csr_mon_intr      => 20,
      csr_mon_timeout   => 30,
      csr_timeout       => 360,
      service_title     => 'ceilometer-alarm-evaluator',
      hasrestart        => false,
    }
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
