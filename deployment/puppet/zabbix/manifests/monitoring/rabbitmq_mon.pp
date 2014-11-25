class zabbix::monitoring::rabbitmq_mon {

  include zabbix::params

  if $::fuel_settings["deployment_mode"] == "multinode" {
    $template = "Template App OpenStack RabbitMQ"
    $service_name = "${zabbix::params::openstack::rabbitmq_service_name}"
  } else {
    $template = "Template App OpenStack HA RabbitMQ"
    $service_name = "p_${zabbix::params::openstack::rabbitmq_service_name}"
  }

  #RabbitMQ server
  if defined_in_state(Class['rabbitmq::server']) {

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack RabbitMQ":
      host     => $zabbix::params::host_name,
      template => $template,
      api      => $zabbix::monitoring::api_hash,
    }

    Exec['enable rabbitmq management plugin'] ->
    Service["$service_name"]

    exec { 'enable rabbitmq management plugin':
      command     => 'rabbitmq-plugins enable rabbitmq_management',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      unless      => 'rabbitmq-plugins list -m -E rabbitmq_management | grep -q rabbitmq_management',
      environment => "HOME=/root",
      notify      => Service[$service_name]
    }

    if $::fuel_settings["deployment_mode"] == "multinode" {
      service { "$service_name":
        ensure => 'running'
      }
    } else {
      service { "$service_name":
        ensure   => "running",
        provider => 'pacemaker'
      }
    }

    firewall {'992 rabbitmq management':
      port   => '15672',
      proto  => 'tcp',
      action => 'accept',
    }

    sysctl::value { 'net.ipv4.ip_local_reserved_ports': value => '15672' }

    zabbix::agent::userparameter {
      'rabbitmq.queue.items':
        command => "/etc/zabbix/scripts/check_rabbit.py queues-items";
      'rabbitmq.queues.without.consumers':
        command => "/etc/zabbix/scripts/check_rabbit.py queues-without-consumers";
      'rabbitmq.missing.nodes':
        command => "/etc/zabbix/scripts/check_rabbit.py missing-nodes";
      'rabbitmq.unmirror.queues':
        command => "/etc/zabbix/scripts/check_rabbit.py unmirror-queues";
      'rabbitmq.missing.queues':
        command => "/etc/zabbix/scripts/check_rabbit.py missing-queues";
    }
  }
}
