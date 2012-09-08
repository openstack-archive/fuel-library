define sysctl::value (
  $value,
  $key = 'name'
) {

  $array = split($value,'[\s\t]')
  $val1 = inline_template("<%= array.delete_if(&:empty?).flatten.join(\"\t\") %>")

  $real_key = $key ? {
    'name'  => $name,
    default => $key,
  }

  sysctl { $real_key :
    val    => $val1,
    before => Exec["exec_sysctl_${real_key}"],
  }

  $command = $::kernel ? {
    openbsd => "sysctl ${real_key}=\"${val1}\"",
    default => "sysctl -w ${real_key}=\"${val1}\"",
  }

  $unless = $::kernel ? {
    openbsd => "sysctl ${real_key} | grep -q '=${val1}\$'",
    default => "sysctl ${real_key} | grep -q ' = ${val1}'",
  }

  exec { "exec_sysctl_${real_key}" :
      command => $command,
      unless  => $unless,
      require => Sysctl[$real_key],
  }
}
