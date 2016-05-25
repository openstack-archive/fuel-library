notice('MODULAR: dump_rabbitmq_definitions.pp')

$definitions_dump_file = '/etc/rabbitmq/definitions'
$rabbit_hash     = hiera_hash('rabbit_hash',
    {
      'user'     => false,
      'password' => false,
    }
  )
$rabbit_enabled  = pick($rabbit_hash['enabled'], true)


if ($rabbit_enabled) {
  $rabbit_api_endpoint = 'http://localhost:15672/api/definitions'
  $rabbit_credentials  = "${rabbit_hash['user']}:${rabbit_hash['password']}"
  $filter = '/tmp/filter_rabbitmq_definitions.py'

  file { $filter:
    ensure  => file,
    content => template('osnailyfacter/filter_rabbitmq_definitions.py'),
  }

  exec { 'rabbitmq-dump-definitions':
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    command => "curl -u ${rabbit_credentials} ${rabbit_api_endpoint} | python ${filter} > ${definitions_dump_file}",
  }

  file { $definitions_dump_file:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }
}
