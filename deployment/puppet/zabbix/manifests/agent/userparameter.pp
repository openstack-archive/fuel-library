# == Define: zabbix::agent::userparameter
#
# Create a userparameter on a zabbix agent. This works in tandem with
# zabbix::server::item to monitor resources.
#
# This is usually used to create an additional config file per UserParameter
# needed on the agent node.
#
# === Parameters
# [*ensure*]
#   present or absent
# [*key*]
#   unique key for zabbix
# [*command*]
#   command to execute as UserParamter
# [*path*]
#   path to use for zabbix conf Include dir, default is
#   '/etc/zabbix/zabbix_agentd.d'
# [*index*]
#   index number to prefix to UserParameters conf file, default is '10'
# [*file*]
#   full path to file puppet should manage
# [*template*]
#   template to use for UserParameter conf file contents
#
# === Example Usage
#
#   zabbix::agent::param { 'zabbix.key.test':
#     ensure => 'present',
#     command => 'echo "Hello World!"'
#   }
#
# === TODO
#
# * rewrite to $zabbix::params
#
define zabbix::agent::userparameter (
  $ensure   = present,
  $command  = undef,
  $key      = undef,
  $index    = undef,
  $file     = undef,
  $template = 'zabbix/zabbix_agent_userparam.conf.erb'
) {

  include zabbix::params
  
  $key_real = $key ? {
    undef   => $name,
    default => $key
  }
  
  $index_real = $index ? {
    undef => '',
    default => "${index}_",
  }

  $file_real = $file ? {
    undef   => "${::zabbix::params::agent_include_path}/${index_real}${name}.conf",
    default => $file,
  }

  file { $file_real:
    ensure  => $ensure,
    content => template($template),
    notify  => Service[$zabbix::params::agent_service_name]
  }

}
