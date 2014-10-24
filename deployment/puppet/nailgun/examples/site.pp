$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and $::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

$env_path = "/usr"
$staticdir = "/usr/share/nailgun/static"

# this replaces removed postgresql version fact
$postgres_default_version = '8.4'

node default {

  Exec  {path => '/usr/bin:/bin:/usr/sbin:/sbin'}

  $centos_repos =
  [
   {
   "id" => "nailgun",
   "name" => "Nailgun",
   "url"  => "\$tree"
   },
   ]

  $cobbler_user = $::fuel_settings['cobbler']['user']
  $cobbler_password = $::fuel_settings['cobbler']['password']
  $puppet_master_hostname = "${hostname}.${domain}"

  $mco_pskey = "unset"
  $mco_vhost = "mcollective"
  $mco_user = $::fuel_settings['mcollective']['user']
  $mco_password = $::fuel_settings['mcollective']['password']
  $mco_connector = "rabbitmq"

  $rabbitmq_host = $::fuel_settings['ADMIN_NETWORK']['ipaddress']
  $rabbitmq_astute_user = $::fuel_settings['astute']['user']
  $rabbitmq_astute_password = $::fuel_settings['astute']['password']

  $repo_root = "/var/www/nailgun"
  $pip_repo = "/var/www/nailgun/eggs"
  $gem_source = "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:8080/gems/"

  class { 'postgresql::server':
    config_hash => {
      'ip_mask_allow_all_users' => '0.0.0.0/0',
      'listen_addresses'        => '127.0.0.1',
    },
  }

  $ntp_servers = [$::fuel_settings['NTP1'], $::fuel_settings['NTP2'], $::fuel_settings['NTP3']]

  class { "openstack::clocksync":
    ntp_servers     => $ntp_servers,
    config_template => "ntp/ntp.conf.centosserver.erb",
  }

  class { "nailgun":
    package => "Nailgun",
    version => "0.1.0",
    production => $production,
    astute_version => "0.0.2",
    nailgun_group => "nailgun",
    nailgun_user => "nailgun",
    venv => $env_path,

    pip_index => "--no-index",
    pip_find_links => "-f file://${pip_repo}",
    gem_source => $gem_source,

    # it will be path to database file while using sqlite
    # (this is not implemented now)
    database_name => $::fuel_settings['postgres']['nailgun_dbname'],
    database_engine => "postgresql",
    database_host => "localhost",
    database_port => "5432",
    database_user => $::fuel_settings['postgres']['nailgun_user'],
    database_passwd => $::fuel_settings['postgres']['nailgun_password'],

    staticdir => $staticdir,
    templatedir => $staticdir,

    cobbler_url => "http://localhost/cobbler_api",
    cobbler_user => $cobbler_user,
    cobbler_password => $cobbler_password,

    mco_pskey => $mco_pskey,
    mco_vhost => $mco_vhost,
    mco_host => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    mco_user => $mco_user,
    mco_password => $mco_password,
    mco_connector => "rabbitmq",

    rabbitmq_astute_user => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,
    puppet_master_hostname => $puppet_master_hostname,
    puppet_master_ip => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],

    keystone_admin_token => $::fuel_settings['keystone']['admin_token'],
    keystone_host        => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
  }

  Class['postgresql::server'] -> Class['nailgun']

}
