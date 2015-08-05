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
# Limit HTTP traffic (per client) to reserve some bandwidth for DHCP
# and TFTP traffic. The restriction applies to /bootstrap location only.
# The default value is enough for booting 200 nodes via a 10Gb link:
# 9 Gb/sec / 200 nodes ~ 5 MB/sec per a node (and 1Gb/sec is reserved
# to avoid excessive collisions which kill UDP traffic).
# Unfortunately this means a bootstrap node is going to download its root
# image for almost 40 sec.
$bootstrap_settings = pick($::fuel_settings['BOOTSTRAP'], {})
$bootstrap_limit_rate = pick($bootstrap_settings['limit_rate'], '5M')

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
      ssl_enabled     => true,
      bootstrap_limit_rate => $bootstrap_limit_rate,
  }
}
