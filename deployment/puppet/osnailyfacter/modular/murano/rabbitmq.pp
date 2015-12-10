notice('MODULAR: murano/rabbitmq.pp')

$rabbit_hash          = hiera_hash('rabbit_hash', {})

if $rabbit_hash == {} {
  fail('No rabbit_hash defined')
}

$rabbit_user          = $rabbit_hash['user']
$rabbit_password      = $rabbit_hash['password']
$rabbit_vhost         = '/'

$rabbit_node_name     = 'murano@localhost'
$rabbit_service_name  = 'rabbitmq-server-murano'

#################################################################

package { 'murano-rabbitmq':
  ensure => present,
}

service { $rabbit_service_name :
  ensure => 'running',
  name   => $rabbit_service_name,
  enable => true,
}

exec { 'remove_murano_guest' :
  command => "rabbitmqctl -n '${rabbit_node_name}' delete_user guest",
  onlyif  => "rabbitmqctl -n '${rabbit_node_name}' list_users | grep -qE '^guest\\s*\\['",
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
}

exec { 'create_murano_user' :
  command => "rabbitmqctl -n '${rabbit_node_name}' add_user '${rabbit_user}' '${rabbit_password}'",
  unless  => "rabbitmqctl -n '${rabbit_node_name}' list_users | grep -qE '^${rabbit_user}\\s*\\['",
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
}

exec { 'create_murano_vhost' :
  command => "rabbitmqctl -n '${rabbit_node_name}' add_vhost '${rabbit_vhost}'",
  unless  => "rabbitmqctl -n '${rabbit_node_name}' list_vhosts | grep -qE '^${rabbit_vhost}$'",
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
}

exec { 'set_murano_user_permissions' :
  command => "rabbitmqctl -n '${rabbit_node_name}' set_permissions -p '${rabbit_vhost}' '${rabbit_user}' '.*' '.*' '.*'",
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
}

Package['murano-rabbitmq'] ->
  Service['rabbitmq-server-murano']

Package['murano-rabbitmq'] ~> Service['rabbitmq-server-murano']

Service['rabbitmq-server-murano'] ->
  Exec['remove_murano_guest'] ->
    Exec['create_murano_user'] ->
      Exec['create_murano_vhost'] ->
        Exec['set_murano_user_permissions']
