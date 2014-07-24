$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

if $production == 'prod'{
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

# this replaces removed postgresql version fact
$postgres_default_version = '8.4'


node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  Class['nailgun::packages'] ->
  Class['nailgun::ostf'] ->
  Class['nailgun::supervisor']

  class { "nailgun::packages": }

  class { "nailgun::ostf":
    production   => $production,
    pip_opts     => "${pip_index} ${pip_find_links}",
    dbname       => $::fuel_settings['postgres']['ostf_dbname'],
    dbuser       => $::fuel_settings['postgres']['ostf_user'],
    dbpass       => $::fuel_settings['postgres']['ostf_password'],
    dbhost       => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    dbport       => '5432',
    nailgun_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    nailgun_port => '8000',
    host         => "0.0.0.0",
    auth_enable  => 'True',

    keystone_admin_token => $::fuel_settings['keystone']['admin_token'],
    keystone_host        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  }
  class { "nailgun::supervisor":
    nailgun_env   => $env_path,
    ostf_env      => $env_path,
    conf_file => "nailgun/supervisord.conf.base.erb",
  }

}
