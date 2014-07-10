class zabbix::monitoring::rabbitmq_mon {

  include zabbix::params

  if $::fuel_settings["deployment_mode"] == "multinode" {
    $template = "Template App OpenStack RabbitMQ"
  } else {
    $template = "Template App OpenStack HA RabbitMQ"
  }

  #RabbitMQ server
  if defined(Class['rabbitmq::server']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack RabbitMQ":
      host => $zabbix::params::host_name,
      template => $template,
      api => $zabbix::params::api_hash,
    }
    Class['nova::rabbitmq'] ->
    exec { 'enable rabbitmq management plugin':

      command => 'rabbitmq-plugins enable rabbitmq_management',
      path    => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      unless  => 'rabbitmq-plugins list -m -E rabbitmq_management | grep -q rabbitmq_management',
      notify  => Exec['restart rabbitmq'],
      environment => "HOME=/root"
    }
    exec { 'restart rabbitmq':
      command     => 'service rabbitmq-server restart',
      path        => ['/usr/sbin', '/usr/bin', '/sbin', '/bin' ],
      refreshonly => true,
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
