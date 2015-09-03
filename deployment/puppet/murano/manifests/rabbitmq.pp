# == Class: murano::rabbitmq
#
#  murano rabbitmq configuration
#
# === Parameters
#
# [*rabbit_user*]
#  (Optional)
#  Defaults to 'murano'
#
# [*rabbit_password*]
#  (Optional)
#  Defaults to 'murano'
#
# [*rabbit_vhost*]
#  (Optional)
#  Defaults to '/'
#
# [*rabbit_port*]
#  (Optional)
#  Defaults to '55572'
#
# [*rabbit_cluster_port*]
#  (Optional)
#  Defaults to '41056'
#
# [*rabbit_node_name*]
#  (Optional)
#  Defaults to 'murano@localhost'
#
# [*rabbit_config_path*]
#  (Optional)
#  Defaults to '/etc/rabbitmq/rabbitmq-murano.config'
#
# [*firewall_rule_name*]
#  (Optional)
#  Defaults to '203 murano-rabbitmq'
#
class murano::rabbitmq(
  $rabbit_user         = 'murano',
  $rabbit_password     = 'murano',
  $rabbit_vhost        = '/',
  $rabbit_port         = '55572',
  $rabbit_cluster_port = '41056',
  $rabbit_node_name    = 'murano@localhost',
  $rabbit_config_path  = '/etc/rabbitmq/rabbitmq-murano.config',
  $firewall_rule_name  = '203 murano-rabbitmq',
) {

  include ::rabbitmq::params

  ensure_packages([$rabbitmq::params::package_name],
    {
      ensure   => $rabbitmq::params::package_ensure,
      provider => $rabbitmq::params::package_provider,
      before   => File['rabbitmq_config'],
    }
  )

  file { 'rabbitmq_config' :
    path    => $rabbit_config_path,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => template('murano/rabbitmq.config.erb'),
  }

  file { 'init_script' :
    path    => "/etc/init.d/${::murano::params::rabbit_service_name}",
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template("murano/${::murano::params::init_script_file}"),
  }

  exec { 'install_init_script' :
    command => $::murano::params::init_install_cmd,
    path    => [ '/bin', '/sbin', '/usr/bin', '/usr/sbin' ],
    unless  => "test -f /etc/init.d/${::murano::params::rabbit_service_name}"
  }

  service { 'rabbitmq-server-murano' :
    ensure => 'running',
    name   => $::murano::params::rabbit_service_name,
    enable => true,
  }

  firewall { $firewall_rule_name :
    dport  => [ $rabbit_port ],
    proto  => 'tcp',
    action => 'accept',
  }

  if $rabbit_user == 'guest' {
    fail('Murano user should not be guest!')
  }

  # evil hack to workaround resource duplication restrictions between main and Murano RabbitMQ instances
  # and other problems that doesn't allow me to use Puppet resources here
  # passing variables from nailgun to exec can theoretically allow shell injection attacks
  # well... but if you can pass variables to nailgun you already can do anything you want anyway

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

  Firewall[$firewall_rule_name] -> Service['rabbitmq-server-murano']
  File['rabbitmq_config'] ~> Service['rabbitmq-server-murano']
  File['init_script'] ~> Service['rabbitmq-server-murano']

  Service['rabbitmq-server-murano'] ->
    Exec['remove_murano_guest'] ->
      Exec['create_murano_user'] ->
        Exec['create_murano_vhost'] ->
          Exec['set_murano_user_permissions']

}
