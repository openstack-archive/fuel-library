# RabbitMQ connections cleanup
class openstack::ha::rabbitmq_connections_cleanup (
  $rabbit_virtual_host = '/',
  $rabbit_userid       = $::openstack::controller_ha::amqp_user,
  $rabbit_password     = $::openstack::controller_ha::amqp_password,
) {

  exec {'rabbitmq-plugins enable rabbitmq_management':
    path        => '/sbin:/bin:/usr/sbin:/usr/bin',
    environment => 'HOME=/root',
    require     => Package[$::rabbitmq::server::package_name],
    notify      => Service[$::rabbitmq::service::service_name],
  }

  package {'python-rabbit': }

  file {'rabbitmq-connections-cleanup':
    path    => '/usr/local/bin/rabbitmq-connections-cleanup',
    content => template('openstack/rabbitmq-connections-cleanup'),
    owner   => '0',
    group   => '0',
    mode    => '0755',
    require => Package['python-rabbit'],
  }

  file {'rabbitmq-connections-cleanup.conf':
    path    => '/root/rabbitmq-connections-cleanup.conf',
    content => template('openstack/rabbitmq-connections-cleanup.conf.erb'),
  }

  cron {'rabbitmq-connections-cleanup':
    command => '/usr/local/bin/rabbitmq-connections-cleanup /root/rabbitmq-connections-cleanup.conf',
    user    => 'root',
    minute  => '*/1',
    require => [File['rabbitmq-connections-cleanup',
                     'rabbitmq-connections-cleanup.conf'],
                Exec['rabbitmq-plugins enable rabbitmq_management'],
                Service[$::rabbitmq::service::service_name]],
  }
}
