notice('MODULAR: dump_rabbitmq_definitions.pp')

$definitions_dump_file = '/etc/rabbitmq/definitions'
$original_definitions_dump_file = '/etc/rabbitmq/definitions.full'
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

  exec { 'rabbitmq-dump-definitions':
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    command => "curl -u ${rabbit_credentials} ${rabbit_api_endpoint} -o ${original_definitions_dump_file}",
  }->
  exec { 'rabbitmq-dump-clean':
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    command => "rabbitmq-dump-clean.py < ${original_definitions_dump_file} > ${definitions_dump_file}",
  }

  file { [$definitions_dump_file, $original_definitions_dump_file]:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }
}
