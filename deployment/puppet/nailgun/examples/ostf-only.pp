$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

if $production == 'prod'{
  $env_path = "/usr"
  $staticdir = "/usr/share/nailgun/static"
} else {
  $env_path = "/opt/nailgun"
  $staticdir = "/opt/nailgun/share/nailgun/static"
}

# this replaces removed postgresql version fact
$postgres_default_version = '9.3'

case $::osfamily {
  'RedHat': {
    if $::operatingsystemrelease =~ /^7.*/ {
      $systemd = true
    } else {
      $systemd = false
    }
  }
  default: { $systemd = false }
}

node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  if $systemd {
    Class['docker::container'] ->
    Class['nailgun::packages'] ->
    Class['nailgun::ostf'] ->
    Class['nailgun::systemd']
  } else {
    Class['docker::container'] ->
    Class['nailgun::packages'] ->
    Class['nailgun::ostf'] ->
    Class['nailgun::supervisor']
  }

  class {'docker::container': }
  class { "nailgun::packages": }

  class { "nailgun::ostf":
    production   => $production,
    systemd      => $systemd,
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

    keystone_host      => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    keystone_ostf_user => $::fuel_settings['keystone']['ostf_user'],
    keystone_ostf_pass => $::fuel_settings['keystone']['ostf_password'],
  }

  if $systemd {
    class { "nailgun::systemd":
      services => ['ostf']
    }
  } else {
    class { "nailgun::supervisor":
      nailgun_env   => $env_path,
      ostf_env      => $env_path,
      conf_file => "nailgun/supervisord.conf.base.erb",
    }
  }

}
