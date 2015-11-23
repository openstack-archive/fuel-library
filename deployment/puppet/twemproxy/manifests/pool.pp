define twemproxy::pool (
  $order                = '00',
  $listen_address       = $twemproxy::params::listen_address,
  $listen_port          = $twemproxy::params::listen_port,
  $connections          = $twemproxy::params::client_connections,
  $hash                 = $twemproxy::params::hash,
  $hash_tag             = $twemproxy::params::hash_tag,
  $distribution         = $twemproxy::params::distribution,
  $timeout              = $twemproxy::params::timeout,
  $backlog              = $twemproxy::params::backlog,
  $preconnect           = $twemproxy::params::preconnect,
  $redis                = $twemproxy::params::redis,
  $redis_auth           = $twemproxy::params::redis_auth,
  $redis_db             = $twemproxy::params::redis_db,
  $server_connections   = $twemproxy::params::server_connections,
  $auto_eject_hosts     = $twemproxy::params::auto_eject_hosts,
  $server_retry_timeout = $twemproxy::params::server_retry_timeout,
  $server_failure_limit = $twemproxy::params::server_failure_limit,
  $client_address       = undef,
  $clients_array        = undef,
  $client_port          = $twemproxy::params::client_port,
  $client_weight        = $twemproxy::params::client_weight,
) {

  if !$client_address and !$clients_array {
    fail('You must set at least one of client_address or clients_array parameter.')
  }

  twemproxy::listen { $name:
    order                => $order,
    listen_address       => $listen_address,
    listen_port          => $listen_port,
    connections          => $connections,
    hash                 => $hash,
    hash_tag             => $hash_tag,
    distribution         => $distribution,
    timeout              => $timeout,
    backlog              => $backlog,
    preconnect           => $preconnect,
    redis                => $redis,
    redis_auth           => $redis_auth,
    redis_db             => $redis_db,
    server_connections   => $server_connections,
    auto_eject_hosts     => $auto_eject_hosts,
    server_retry_timeout => $server_retry_timeout,
    server_failure_limit => $server_failure_limit,
  }

  twemproxy::member { $name:
    order          => $order,
    client_address => $client_address,
    client_port    => $client_port,
    client_weight  => $client_weight,
    clients_array  => $clients_array,
  }
}
