notice('MODULAR: dump_rabbitmq_users.pp')

$users_dump_file    = '/etc/rabbitmq/users'
$rabbit_hash        = hiera('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )

exec {'dump users':
  path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
  command => "curl -u ${rabbit_hash['user']}:${rabbit_hash[password]} localhost:15672/api/users -o ${users_dump_file}",
}
