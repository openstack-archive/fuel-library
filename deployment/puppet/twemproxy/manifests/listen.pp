define twemproxy::listen (
  $order,
  $listen_address,
  $listen_port,
  $hash,
  $distribution,
  $auto_eject_hosts     = false,
  $backlog              = undef,
  $connections          = undef,
  $hash_tag             = undef,
  $preconnect           = false,
  $redis                = false,
  $redis_auth           = false,
  $redis_db             = false,
  $server_connections   = undef,
  $server_retry_timeout = undef,
  $server_failure_limit = undef,
  $timeout              = undef,
) {

  concat { '/etc/nutcracker.yml':
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${name}_listen_block":
    order   => "00_${order}",
    target  => '/etc/nutcracker.yml',
    content => template('twemproxy/twemproxy_listen_block.erb'),
  }
}
