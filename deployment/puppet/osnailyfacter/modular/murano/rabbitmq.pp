notice('MODULAR: murano/rabbitmq.pp')

$rabbit_hash          = hiera_hash('rabbit_hash', {})

$rabbit_user          = $rabbit_hash['user']
$rabbit_password      = $rabbit_hash['password']
$rabbit_vhost         = '/'

$rabbit_port          = '55572'
$rabbit_cluster_port  = '41056'
$rabbit_node_name     = 'murano@localhost'
$rabbit_service_name  = 'rabbitmq-server-murano'
$rabbit_firewall_rule = '203 murano-rabbitmq'

#################################################################

case $::osfamily {
  'RedHat': {
    $init_script_file = 'murano-rabbitmq-init-centos.erb'
    $init_install_cmd = "chkconfig --add '/etc/init.d/${rabbit_service_name}'"
  }
  'Debian': {
    $init_script_file = 'murano-rabbitmq-init-ubuntu.erb'
    $init_install_cmd = "update-rc.d '${rabbit_service_name}' defaults"
  }
  default: {
    fail("Unsupported osfamily: ${::osfamily} operatingsystem: ${::operatingsystem}")
  }
}

file { 'rabbitmq_config' :
  path    => '/etc/rabbitmq/rabbitmq-murano.config',
  owner   => 'root',
  group   => 'root',
  mode    => '0644',
  content => template('osnailyfacter/murano-rabbitmq.config.erb'),
}

file { 'init_script' :
  path    => "/etc/init.d/${rabbit_service_name}",
  owner   => 'root',
  group   => 'root',
  mode    => '0755',
  content => template("osnailyfacter/${init_script_file}"),
}

exec { 'install_init_script' :
  command => $init_install_cmd,
  path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  unless  => "test -f /etc/init.d/${rabbit_service_name}"
}

service { $rabbit_service_name :
  ensure => 'running',
  name   => $rabbit_service_name,
  enable => true,
}

firewall { $rabbit_firewall_rule :
  dport  => [ $rabbit_port ],
  proto  => 'tcp',
  action => 'accept',
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

File['rabbitmq_config'] ->
  File['init_script'] ->
    Exec['install_init_script'] ->
      Service['rabbitmq-server-murano']

Firewall[$rabbit_firewall_rule] -> Service['rabbitmq-server-murano']
File['rabbitmq_config'] ~> Service['rabbitmq-server-murano']
File['init_script'] ~> Service['rabbitmq-server-murano']

Service['rabbitmq-server-murano'] ->
  Exec['remove_murano_guest'] ->
    Exec['create_murano_user'] ->
      Exec['create_murano_vhost'] ->
        Exec['set_murano_user_permissions']
