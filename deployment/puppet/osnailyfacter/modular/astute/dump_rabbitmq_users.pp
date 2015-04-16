notice('MODULAR: dump_rabbitmq_users.pp')

$users_dump_file = '/etc/rabbitmq/users'
$rabbit_hash     = hiera_hash('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )
$rabbit_enabled  = pick($rabbit_hash['enabled'], true)


if ($rabbit_enabled) {
  $rabbit_api_endpoint = 'http://localhost:15672/api/users'
  $rabbit_credentials  = "${rabbit_hash['user']}:${rabbit_hash['password']}"

  exec { 'rabbitmq-dump-users':
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    command => "curl -u ${rabbit_credentials} ${rabbit_api_endpoint} -o ${users_dump_file}",
  }

  file { $users_dump_file:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }
}
