notice('MODULAR: dump_rabbitmq_users.pp')

$users_dump_file    = '/etc/rabbitmq/users'
$rabbit_hash        = hiera_hash('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )

exec {'dump users':
  path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
  command => "curl -u ${rabbit_hash['user']}:${rabbit_hash[password]} localhost:15672/api/users -o ${users_dump_file}",
}

file { $users_dump_file:
  ensure => file,
  owner  => 'root',
  group  => 'root',
  mode   => '0600',
}
