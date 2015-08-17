$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and
$::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
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
$ubuntu_repo = pick($::fuel_settings['MIRROR_UBUNTU'], "http://archive.ubuntu.com/ubuntu")
$mos_repo    = pick($::fuel_settings['MIRROR_MOS'], "http://mirror.fuel-infra.org/mos-repos")

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
      service_enabled => false,
      ubuntu_repo     => $ubuntu_repo,
      mos_repo        => $mos_repo,
      ssl_enabled     => true,
      force_https     => $force_https,
  }
}
