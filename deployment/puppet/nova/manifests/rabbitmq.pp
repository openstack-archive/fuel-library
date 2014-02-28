#
# class for installing rabbitmq server for nova
#
#
class nova::rabbitmq(
  $userid='guest',
  $password='guest',
  $port='5672',
  $virtual_host='/',
  $cluster = false,
  $cluster_nodes = [], #Real node names to install RabbitMQ server onto.
  $enabled = true,
  $rabbit_node_ip_address = 'UNSET',
  $ha_mode = false,
  $primary_controller = false
) {

  # only configure nova after the queue is up
  Class['rabbitmq::service'] -> Anchor<| title == 'nova-start' |>

  if ($enabled) {
    if $userid == 'guest' {
      $delete_guest_user = false
    } else {
      $delete_guest_user = true
    }
    $service_ensure = 'running'
    $service_enabled  = true
  } else {
    $service_ensure = 'stopped'
    $service_enabled  = false
  }

  if ($ha_mode) {
    $service_provider = 'pacemaker'
    $service_name     = 'p_rabbitmq-server'
  } else {
    $service_provider = undef
    $service_name     = 'rabbitmq-server'
  }

  if ($ha_mode and ! $primary_controller) {
    $real_delete_guest_user = false
  } else {
    $real_delete_guest_user = $delete_guest_user
  }

  class { 'rabbitmq::server':
    service_name       => $service_name,
    service_ensure     => $service_ensure,
    service_provider   => $service_provider,
    service_enabled    => $service_enabled,
    port               => $port,
    delete_guest_user  => $real_delete_guest_user,
    config_cluster     => $cluster,
    cluster_disk_nodes => $cluster_nodes,
    version            => $::openstack_version['rabbitmq_version'],
    node_ip_address    => $rabbit_node_ip_address
  }

  if ($ha_mode) {
    # OCF script for pacemaker
    # and his dependences
    file {'rabbitmq-ocf':
      path   =>'/usr/lib/ocf/resource.d/mirantis/rabbitmq-server',
      mode   => '0755',
      owner  => root,
      group  => root,
      source => "puppet:///modules/nova/ocf/rabbitmq",
    }

    # Disable OS-aware service, because rabbitmq-server managed by Pacemaker.
    service {'rabbitmq-server__disabled':
      name       => 'rabbitmq-server',
      ensure     => 'stopped',
      enable     => false,
    }

    File<| title == 'ocf-mirantis-path' |> -> File['rabbitmq-ocf']
    Package['pacemaker'] -> File<| title == 'ocf-mirantis-path' |>
    Package['pacemaker'] -> File['rabbitmq-ocf']
    Package['rabbitmq-server'] ->
      Service['rabbitmq-server__disabled'] ->
        File['rabbitmq-ocf'] ->
          Service["$service_name"]
    if ($primary_controller) {
      cs_resource {"$service_name":
        ensure          => present,
        #cib             => 'rabbitmq',
        primitive_class => 'ocf',
        provided_by     => 'mirantis',
        primitive_type  => 'rabbitmq-server',
        parameters      => {
          'node_port'     => $port,
          #'debug'         => true,
        },
        metadata => {
           'migration-threshold' => 'INFINITY'
        },
        multistate_hash => {
          'type' => 'master',
        },
        ms_metadata => {
          'notify'      => 'true',
          'ordered'     => 'true',
          'interleave'  => 'false',  # We shouldn't enable interleave, for parallel start of RA.
          'master-max'  => '1',
          'master-node-max' => '1',
          'target-role' => 'Master'
        },
        operations => {
          'monitor' => {
            'interval' => '30',
            'timeout'  => '60'
          },
          'monitor:Master' => { # name:role
            'role' => 'Master',
            'interval' => '27', # should be non-intercectable with interval from ordinary monitor
            'timeout'  => '60'
          },
          'start' => {
            'timeout' => '120'
          },
          'stop' => {
            'timeout' => '60'
          },
          'promote' => {
            'timeout' => '120'
          },
          'demote' => {
            'timeout' => '60'
          },
          'notify' => {
            'timeout' => '60'
          },
        },
      }
      File['rabbitmq-ocf'] ->
        Cs_resource["$service_name"] ->
          Service["$service_name"]
    }

    exec { 'waiting for start rabbitmq-master':
       command => '/bin/sleep 120'
    }

    Service["$service_name"] ->
      Exec['waiting for start rabbitmq-master'] ->
        Rabbitmq_user <||>
  }

}
