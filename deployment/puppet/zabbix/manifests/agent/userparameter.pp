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
    undef   => "${::zabbix::params::agent_include}/${index_real}${name}.conf",
    default => $file,
  }

  file { $file_real:
    ensure  => $ensure,
    content => template($template),
    notify  => Service[$zabbix::params::agent_service]
  }
}
