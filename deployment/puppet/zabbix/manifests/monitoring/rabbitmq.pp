class zabbix::monitoring::rabbitmq inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    #RabbitMQ server
    zabbix_template_link { "${host_name} Template App OpenStack RabbitMQ":
      host     => $host_name,
      template => "Template App OpenStack HA RabbitMQ",
      api      => $api_hash,
    }

    Package <| title == 'rabbitmq-server' |> ->
    Exec['enable rabbitmq management plugin'] ~>
    Service <| title == 'rabbitmq-server' |>

    exec { 'enable rabbitmq management plugin':
      command     => 'rabbitmq-plugins enable rabbitmq_management',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      unless      => 'rabbitmq-plugins list -m -E rabbitmq_management | grep -q rabbitmq_management',
      environment => "HOME=/root",
    }

    firewall {'992 rabbitmq management':
      port   => 55672,
      proto  => 'tcp',
      action => 'accept',
    }

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
