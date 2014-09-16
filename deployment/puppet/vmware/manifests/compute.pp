# This resource creates nova-compute service for provided vSphere
# clusters (cluster that is formed of ESXi hosts and is managed by vCenter
# server.
define vmware::compute(
  $amqp_port = '5673',
  $api_retry_count = 5,
  $compute_driver = 'vmwareapi.VMwareVCDriver',
  $maximum_objects = 100,
  $nova_conf = '/etc/nova/nova.conf',
  $task_poll_interval = 5.0,
  $use_linked_clone = true,
)
{
  $nova_compute_conf = "/etc/nova/nova-compute-${name}.conf"

  file { "${nova_compute_conf}":
    content => template("vmware/nova-compute.conf.erb"),
    mode => 0644,
    owner => root,
    group => root,
    ensure => present,
  }

  cs_resource { "p_vcenter_nova_compute_${name}":
    ensure          => present,
    primitive_class => 'ocf',
    provided_by     => 'mirantis',
    primitive_type  => 'nova-compute',
    metadata        => {
      resource-stickiness => '1'
    },
    parameters      => {
      amqp_server_port      => $amqp_port,
      config                => $nova_conf,
      pid                   => "/var/run/nova/nova-compute-${name}.pid",
      additional_parameters => "--config-file=${nova_compute_conf}",
    },
    operations      => {
      monitor  => {
        interval => '20',
        timeout  => '10',
      },
        start  => {
        timeout => '30',
      },
        stop   => {
        timeout => '30',
      }
    }
  }

  service { "p_vcenter_nova_compute_${name}":
    ensure => running,
    enable => true,
    provider => 'pacemaker',
  }
}
