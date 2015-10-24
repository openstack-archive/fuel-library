notice('MODULAR: murano/rabbitmq.pp')

$rabbit_hash                = hiera_hash('rabbit_hash', {})

#################################################################

rabbitmq_vhost { '/murano': }

rabbitmq_user_permissions { "${rabbit_hash['user']}@/murano":
    configure_permission => '.*',
    read_permission      => '.*',
    write_permission     => '.*',
}
