notice('MODULAR: dump_rabbitmq_definitions.pp')

$definitions_dump_file = '/etc/rabbitmq/definitions'
$rabbit_hash     = hiera_hash('rabbit', {})
$rabbit_enabled  = pick($rabbit_hash['enabled'], true)
$rabbit_user     = pick($rabbit_hash['user'], 'nova')
$rabbit_password = $rabbit_hash['password']

if ($rabbit_enabled) {
  $rabbit_api_endpoint = 'http://localhost:15672/api/definitions'
  $rabbit_credentials  = "${rabbit_user}:${rabbit_password}"

  exec { 'rabbitmq-dump-definitions':
    path    => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
    command => "curl -u ${rabbit_credentials} ${rabbit_api_endpoint} -o ${definitions_dump_file}",
  }

  file { $definitions_dump_file:
    ensure => file,
    owner  => 'root',
    group  => 'root',
    mode   => '0600',
  }
}
