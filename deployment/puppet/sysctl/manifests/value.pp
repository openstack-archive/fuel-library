# Manage sysctl value
#
# It not only manages the entry within
# /etc/sysctl.conf, but also checks the
# current active version.
define sysctl::value (
  $value,
  $key    = $name,
) {

  $array = split($value,'[\s\t]')
  $val1 = inline_template("<%= @array.reject(&:empty?).flatten.join(\"\t\") %>")

  sysctl { $key :
    val => $val1,
  }

  $command = $::kernel ? {
    /i?BSD$/ => shellquote('sysctl',     "${key}=${val1}"),
    default  => shellquote('sysctl','-w',"${key}=${val1}"),
  }

  $current_value = shellquote(
    'sysctl',
    '-n',
    $key
  )

  $shellquoted_value = shellquote($val1)
  $unless = "[ \"\$(${current_value})\" = ${shellquoted_value} ]"

  exec { "exec_sysctl_${key}" :
      command => $command,
      unless  => $unless,
      require => Sysctl[$key],
  }

  include sysctl::params
  if $sysctl::params::exec_path {
    Exec["exec_sysctl_${key}"]{
      path => $sysctl::params::exec_path
    }
  }
}
