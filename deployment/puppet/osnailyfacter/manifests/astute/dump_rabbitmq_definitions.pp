class osnailyfacter::astute::dump_rabbitmq_definitions {

  notice('MODULAR: astute/dump_rabbitmq_definitions.pp')

  $definitions_dump_file = '/etc/rabbitmq/definitions'
  $original_definitions_dump_file = '/etc/rabbitmq/definitions.full'
  $rabbit_hash     = hiera_hash('rabbit',
      {
        'user'     => false,
        'password' => false,
      }
    )
  $rabbit_enabled = pick($rabbit_hash['enabled'], true)
  $management_bind_ip_address = hiera('management_bind_ip_address', '127.0.0.1')
  $management_port = hiera('rabbit_management_port', '15672')

  if ($rabbit_enabled) {
    $rabbit_api_endpoint = "http://${management_bind_ip_address}:${management_port}/api/definitions"

    dump_rabbitmq_definitions { $original_definitions_dump_file:
      user     => $rabbit_hash['user'],
      password => $rabbit_hash['password'],
      url      => $rabbit_api_endpoint,
    } ~>
    exec { 'rabbitmq-dump-clean':
      path        => ['/usr/bin', '/usr/sbin', '/sbin', '/bin'],
      command     => "rabbitmq-dump-clean.py < ${original_definitions_dump_file} > ${definitions_dump_file}",
      refreshonly => true,
    }

    file { [$definitions_dump_file, $original_definitions_dump_file]:
      ensure => file,
      owner  => 'root',
      group  => 'root',
      mode   => '0600',
    }
  }

}
