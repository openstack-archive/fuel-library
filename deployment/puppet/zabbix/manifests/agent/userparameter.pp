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

  if $file {
    $file_real = $file
  } elsif $index {
    $file_real = "${agent_include}/${index}_${name}.conf"
  } else {
    $file_real = "${agent_include}/${name}.conf"
  }

  notice("UserParam for: ${parameter_key} at: ${file_real}")

  file { "userparameter-${name}" :
    ensure  => $ensure,
    path    => $file_real,
    content => template($template),
  }

  File["userparameter-${name}"] ~> Service <| title == $agent_service |>
}
