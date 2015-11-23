class twemproxy::params {

  $listen_address       = '127.0.0.1'
  $listen_port          = '22122'
  $client_connections   = 0
  $hash                 = 'md5'
  $hash_tag             = false
  $distribution         = 'ketama'
  $timeout              = 400
  $backlog              = 1024
  $preconnect           = false
  $redis                = false
  $redis_auth           = false
  $redis_db             = false
  $server_connections   = 1
  $auto_eject_hosts     = false
  $server_retry_timeout = 30000
  $server_failure_limit = 2
  $client_port          = 11211
  $client_weight        = 1

  $package_manage       = true
  $package_name         = 'twemproxy'
  $package_ensure       = 'present'

  $service_manage       = true
  $service_enable       = true
  $service_name         = 'twemproxy'
  $service_ensure       = 'running'
}
