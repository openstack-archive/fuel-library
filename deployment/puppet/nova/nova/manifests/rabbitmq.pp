class nova::rabbitmq {
  package { 'rabbitmq-server':
    ensure => installed,
  }
  service { 'rabbitmq-server':
    ensure => running,
    enable => true,
  }
}
