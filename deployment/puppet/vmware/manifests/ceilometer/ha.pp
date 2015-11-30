define vmware::ceilometer::ha (
  $availability_zone_name,
  $vc_cluster,
  $vc_host,
  $vc_user,
  $vc_password,
  $service_name,
  $target_node,
  $datastore_regex = undef,
  $amqp_port = '5673',
  $ceilometer_config   = '/etc/ceilometer/ceilometer.conf',
  $ceilometer_conf_dir = '/etc/ceilometer/ceilometer-compute.d',
) {
  if ($target_node == 'controllers') {
    $ceilometer_compute_conf = "${ceilometer_conf_dir}/vmware-${availability_zone_name}_${service_name}.conf"

    if ! defined(File[$ceilometer_conf_dir]) {
      file { $ceilometer_conf_dir:
        ensure => directory,
        owner  => 'ceilometer',
        group  => 'ceilometer',
        mode   => '0750'
      }
    }

    if ! defined(File[$ceilometer_compute_conf]) {
      file { $ceilometer_compute_conf:
        ensure  => present,
        content => template('vmware/ceilometer-compute.conf.erb'),
        mode    => '0600',
        owner   => 'ceilometer',
        group   => 'ceilometer',
      }
    }

    cs_resource { "p_ceilometer_agent_compute_vmware_${availability_zone_name}_${service_name}":
      ensure          => present,
      primitive_class => 'ocf',
      provided_by     => 'fuel',
      primitive_type  => 'ceilometer-agent-compute',
      metadata        => {
        'target-role' => 'stopped',
        'resource-stickiness' => '1'
      },
      parameters      => {
        amqp_server_port      => $amqp_port,
        config                => $ceilometer_config,
        pid                   => "/var/run/ceilometer/ceilometer-agent-compute-${availability_zone_name}_${service_name}.pid",
        user                  => "ceilometer",
        additional_parameters => "--config-file=${ceilometer_compute_conf}",
      },
      operations      => {
        monitor  => { timeout => '20', interval => '30' },
        start    => { timeout => '360' },
        stop     => { timeout => '360' }
      }
    }

    service { "p_ceilometer_agent_compute_vmware_${availability_zone_name}_${service_name}":
      ensure     => running,
      enable     => true,
      hasstatus  => true,
      hasrestart => true,
      provider   => 'pacemaker',
    }

    File["${ceilometer_conf_dir}"]->
    File["${ceilometer_compute_conf}"]->
    Cs_resource["p_ceilometer_agent_compute_vmware_${availability_zone_name}_${service_name}"]->
    Service["p_ceilometer_agent_compute_vmware_${availability_zone_name}_${service_name}"]
  }
}
