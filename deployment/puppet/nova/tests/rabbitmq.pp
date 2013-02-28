class { 'nova::rabbitmq':
  userid       => 'dan',
  password     => 'password',
  port         => '1234',
  virtual_host => 'my_queue',
}
