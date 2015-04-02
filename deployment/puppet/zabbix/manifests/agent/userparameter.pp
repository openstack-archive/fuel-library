define zabbix::agent::userparameter (
  $ensure   = present,
  $command  = undef,
  $key      = undef,
  $index    = undef,
  $file     = undef,
  $template = 'zabbix/zabbix_agent_userparam.conf.erb'
) {

  include zabbix::params
  $agent_include = $zabbix::params::agent_include
  $agent_service = $zabbix::params::agent_service

  if $key {
    $parameter_key = $key
  } else {
    $parameter_key = $name
  }

  if $index {
    $file = "${agent_include}/${index}_${name}.conf"
  } else {
    $file = "${agent_include}/${name}.conf"
  }

  file { $file:
    ensure  => $ensure,
    content => template($template),
  }

  File[$file] ~> Service[$agent_service]
}
