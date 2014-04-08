$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'dev'
}


class { 'nailgun::host':
  production => $production,
  nailgun_group => $nailgun_group,
  nailgun_user => $nailgun_user,
}

class { "openstack::clocksync":
  ntp_servers     => $ntp_servers,
  config_template => "ntp/ntp.conf.centosserver.erb",
}

class { "docker": }
