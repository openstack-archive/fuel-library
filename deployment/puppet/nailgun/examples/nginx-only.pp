$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

$env_path = "/usr"
$staticdir = "/usr/share/nailgun/static"

# this replaces removed postgresql version fact
$postgres_default_version = '8.4'

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


  class { 'nailgun::nginx':
    production      => $production,
    staticdir       => $staticdir,
    templatedir     => $staticdir,
    logdumpdir      => $logdumpdir,
    ostf_host       => $ostf_host,
    keystone_host   => $keystone_host,
    nailgun_host    => $nailgun_host,
    repo_root       => $repo_root,
    service_enabled => false,
  }
}
