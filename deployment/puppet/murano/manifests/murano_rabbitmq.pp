# This kludge does install another separate instance of RabbitMQ
# to be used by Murano daemons and agents

class murano::murano_rabbitmq(
  $rabbitmq_config_path  = '/etc/rabbitmq/rabbitmq-murano.config',
  $init_script_name      = 'rabbitmq-server-murano',
  $firewall_rule_name    = '203 murano-rabbitmq',
  $rabbit_user           = 'murano',
  $rabbit_password       = 'murano',
  $rabbit_vhost          = '/',
  $rabbitmq_main_port    = '55572',
  $rabbitmq_cluster_port = '41056',
  $rabbitmq_node_name    = 'murano@localhost',
  $rabbitmq_service_name = 'rabbitmq-server-murano',
){

  case $::osfamily {
    'RedHat': {
      $init_install_cmd = "chkconfig --add '/etc/init.d/${init_script_name}'"
      $init_script_file = 'rabbitmq-init-centos.erb'
    }
    'Debian': {
      $init_install_cmd = "update-rc.d '${init_script_name}' defaults"
      $init_script_file = 'rabbitmq-init-ubuntu.erb'
    }
    default: {
      fail("Unsupported osfamily: ${::osfamily}")
    }
  }

  file { 'rabbitmq_config' :
    path    => $rabbitmq_config_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('murano/rabbitmq.config.erb'),
  }

  file { 'init_script' :
    path    => "/etc/init.d/${init_script_name}",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("murano/${init_script_file}"),
  }

  exec { 'install_init_script' :
    command => $init_install_cmd,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  }

  service { 'rabbitmq-server-murano' :
    name    => $rabbitmq_service_name,
    ensure  => 'running',
    enable  => true,
  }

  firewall { $firewall_rule_name :
    dport   => [ $rabbitmq_main_port ],
    proto   => 'tcp',
    action  => 'accept',
  }

  if $rabbit_user == 'guest' {
    fail('Murano user should not be guest!')
  }

  # evil hack to workaround resource duplication restrictions between main and Murano RabbitMQ instances
  # and other problems that doesn't allow me to use Puppet resources here
  # passing variables from nailgun to exec can theoretically allow shell injection attacks
  # well... but if you can pass variables to nailgun you already can do anything you want anyway

  exec { 'remove_murano_guest' :
    command => "rabbitmqctl -n '${rabbitmq_node_name}' delete_user guest",
    onlyif  => "rabbitmqctl -n '${rabbitmq_node_name}' list_users | grep -qE '^guest\\s*'\\[",
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  }

  exec { 'create_murano_user' :
    command => "rabbitmqctl -n '${rabbitmq_node_name}' add_user '${rabbit_user}' '${rabbit_password}'",
    unless  => "rabbitmqctl -n '${rabbitmq_node_name}' list_users | grep -qE '^${rabbit_user}\\s*\\['",
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  }

  exec { 'create_murano_vhost' :
    command => "rabbitmqctl -n '${rabbitmq_node_name}' add_vhost '${rabbit_vhost}'",
    unless  => "rabbitmqctl -n '${rabbitmq_node_name}' list_vhosts | grep -qE '^${rabbit_vhost}$'",
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  }

  # setting permissions to user is already idempotent by its nature
  exec { 'set_murano_user_permissions' :
    command => "rabbitmqctl -n '${rabbitmq_node_name}' set_permissions -p '${rabbit_vhost}' '${rabbit_user}' '.*' '.*' '.*'",
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
  }

  Class['rabbitmq::service'] -> File['rabbitmq_config'] -> File['init_script'] -> Exec['install_init_script'] -> Service['rabbitmq-server-murano']
  Class['openstack::firewall'] -> Firewall[$firewall_rule_name] -> Service['rabbitmq-server-murano']
  File['rabbitmq_config'] ~> Service['rabbitmq-server-murano']
  File['init_script'] ~> Service['rabbitmq-server-murano']
  Service['rabbitmq-server-murano'] -> Exec['remove_murano_guest'] -> Exec['create_murano_user'] -> Exec['create_murano_vhost'] -> Exec['set_murano_user_permissions']

}
