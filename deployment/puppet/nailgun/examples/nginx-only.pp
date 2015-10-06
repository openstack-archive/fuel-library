$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

if $fuel_settings['SSL'] {
  $force_https = $fuel_settings['SSL']['force_https']
} else {
  $force_https = undef
}

$env_path = "/usr"
$staticdir = "/usr/share/nailgun/static"

# this replaces removed postgresql version fact
$postgres_default_version = '9.3'

$centos_repos =
[
  {
     "id" => "nailgun",
     "name" => "Nailgun",
     "url"  => "\$tree"
  },
]

$ostf_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$keystone_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
$nailgun_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']

$repo_root = "/var/www/nailgun"

node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

    class {'docker::container': }

    class { 'nailgun::nginx':
      production      => $production,
      staticdir       => $staticdir,
      templatedir     => $staticdir,
      logdumpdir      => $logdumpdir,
      ostf_host       => $ostf_host,
      keystone_host   => $keystone_host,
      nailgun_host    => $nailgun_host,
      repo_root       => $repo_root,
      service_enabled => true,
      ssl_enabled     => true,
      force_https     => $force_https,
  }
}
