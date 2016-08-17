class openstack_tasks::murano::rabbitmq {

  notice('MODULAR: murano/rabbitmq.pp')

  $murano_hash          = hiera_hash('murano', {})
  $rabbit_user          = pick($murano_hash['rabbit']['user'], 'murano')
  $rabbit_password      = $murano_hash['rabbit_password']
  $rabbit_vhost         = $murano_hash['rabbit']['vhost']

  $rabbit_node_name     = 'murano@localhost'
  $rabbit_service_name  = 'murano-rabbitmq'

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
    Service[$rabbit_service_name]

  Package['murano-rabbitmq'] ~> Service[$rabbit_service_name]

  Service[$rabbit_service_name] ->
    Exec['remove_murano_guest'] ->
      Exec['create_murano_user'] ->
        Exec['create_murano_vhost'] ->
          Exec['set_murano_user_permissions']

}
