class nailgun::nailgun(
  $production        = $::nailgun::params::production,
  $venv              = $::nailgun::params::env_path,
  $staticdir         = $::nailgun::params::staticdir,

  $package           = $::nailgun::params::nailgun_package,
  $version           = $::nailgun::params::nailgun_version,

  $feature_groups = $::nailgun::params::nailgun_feature_groups,
  $log_level      = $::nailgun::params::nailgun_log_level,
  $user           = $::nailgun::params::nailgun_user,
  $group          = $::nailgun::params::nailgun_group,

  $db_name        = $::nailgun::params::nailgun_db_name,
  $db_engine      = $::nailgun::params::nailgun_db_engine,
  $db_host        = $::nailgun::params::nailgun_db_host,
  $db_port        = $::nailgun::params::nailgun_db_port,
  $db_user        = $::nailgun::params::nailgun_db_user,
  $db_password      = $::nailgun::params::nailgun_db_password,

  $admin_network,
  $admin_network_cidr,
  $admin_network_size,
  $admin_network_first,
  $admin_network_last,
  $admin_network_netmask,
  $admin_network_mac,
  $admin_network_ip,
  $admin_network_gateway,

  $cobbler_host     = $::nailgun::params::cobbler_host,
  $cobbler_url      = $::nailgun::params::cobbler_url,
  $cobbler_user     = $::nailgun::params::cobbler_user,
  $cobbler_password = $::nailgun::params::cobbler_password,

  $mco_pskey     = $::nailgun::params::mco_pskey,
  $mco_vhost     = $::nailgun::params::mco_vhost,
  $mco_host      = $::nailgun::params::mco_host,
  $mco_user      = $::nailgun::params::mco_user,
  $mco_password  = $::nailgun::params::mco_password,
  $mco_connector = $::nailgun::params::mco_connector,

  $pip_repo       = $::nailgun::params::pip_repo,
  $gem_source     = $::nailgun::params::gem_source,

  $rabbitmq_host            = $::nailgun::params::rabbit_host,
  $rabbitmq_astute_user     = $::nailgun::params::rabbit_astute_user,
  $rabbitmq_astute_password = $::nailgun::params::rabbit_astute_password,

  $puppet_master_hostname = $::nailgun::params::puppet_master_hostname,

  $keystone_host         = $::nailgun::params::keystone_address,
  $keystone_nailgun_user = $::nailgun::params::keystone_nailgun_user,
  $keystone_nailgun_pass = $::nailgun::params::keystone_nailgun_password,

  $ntp_upstream           = $::nailgun::params::ntp_upstream,
  $dns_upstream           = $::nailgun::params::dns_upstream,
  $dns_domain             = $::nailgun::params::dns_domain,

  $keystone_fuel_user,
  $keystone_fuel_pass,
  $nailgun_host           = $::nailgun::params::nailgun_host,
  $nailgun_port           = $::nailgun::params::nailgun_port,

  ) inherits nailgun::params {


  Class["nailgun::user"] ->
  Class["nailgun::packages"] ->
  Class["nailgun::venv"]

  anchor { "nailgun-begin": } ->
  Class["nailgun::venv"] ->
  anchor { "nailgun-end": }

  class { "nailgun::user":
    nailgun_group => $group,
    nailgun_user => $user,
  }

  class { "nailgun::venv":
    venv => $venv,
    venv_opts => "--system-site-packages",
    package => $package,
    version => $version,
    pip_opts => "--no-index -f ${pip_repo}",
    production => $production,
    nailgun_user => $user,
    nailgun_group => $group,
    feature_groups => $feature_groups,

    database_name => $db_name,
    database_engine => $db_engine,
    database_host => $db_host,
    database_port => $db_port,
    database_user => $db_user,
    database_passwd => $db_password,

    staticdir => $staticdir,
    templatedir => $staticdir,
    rabbitmq_host => $rabbitmq_host,
    rabbitmq_astute_user => $rabbitmq_astute_user,
    rabbitmq_astute_password => $rabbitmq_astute_password,

    nailgun_log_level => $log_level,

    admin_network         => $admin_network,
    admin_network_cidr    => $admin_network_cidr,
    admin_network_size    => $admin_network_size,
    admin_network_first   => $admin_network_first,
    admin_network_last    => $admin_network_last,
    admin_network_netmask => $admin_network_netmask,
    admin_network_mac     => $admin_network_mac,
    admin_network_ip      => $admin_network_ip,
    admin_network_gateway => $admin_network_gateway,

    cobbler_host     => $cobbler_host,
    cobbler_url      => $cobbler_url,
    cobbler_user     => $cobbler_user,
    cobbler_password => $cobbler_password,

    mco_pskey     => $mco_pskey,
    mco_vhost     => $mco_vhost,
    mco_host      => $mco_host,
    mco_user      => $mco_user,
    mco_password  => $mco_password,
    mco_connector => $mco_connector,

    puppet_master_hostname => $puppet_master_hostname,

    keystone_host         => $keystone_host,
    keystone_nailgun_user => $keystone_nailgun_user,
    keystone_nailgun_pass => $keystone_nailgun_pass,

    ntp_upstream => $ntp_upstream,
    dns_upstream => $dns_upstream,
    dns_domain   => $dns_domain,
  }

  class { 'nailgun::uwsgi':
    production => $production,
  }

  class { "nailgun::client":
    server        => $nailgun_host,
    keystone_user => $keystone_fuel_user,
    keystone_pass => $keystone_fuel_pass,
  }

  package { 'crontabs':
    ensure => latest,
  }

  service { 'crond':
    ensure => running,
    enable => true,
  }

  cron { 'oswl_cleaner':
    ensure      => present,
    command     => 'oswl_cleaner',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => $user,
    hour        => '1',
    require     => Package['crontabs'],
  }

}
