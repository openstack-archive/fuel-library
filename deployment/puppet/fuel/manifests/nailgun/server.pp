class fuel::nailgun::server (
  $listen_port               = $::fuel::params::nailgun_internal_port,

  $keystone_host             = $::fuel::params::keystone_host,
  $keystone_user             = $::fuel::params::keystone_nailgun_user,
  $keystone_password         = $::fuel::params::keystone_nailgun_password,

  $feature_groups            = $::fuel::params::feature_groups,
  $nailgun_log_level         = $::fuel::params::nailgun_log_level,

  $db_name                   = $::fuel::params::nailgun_db_name,
  $db_engine                 = $::fuel::params::db_engine,
  $db_host                   = $::fuel::params::db_host,
  $db_port                   = $::fuel::params::db_port,
  $db_user                   = $::fuel::params::nailgun_db_user,
  $db_password               = $::fuel::params::nailgun_db_password,

  $rabbitmq_host             = $::fuel::params::rabbitmq_host,
  $rabbitmq_astute_user      = $::fuel::params::rabbitmq_astute_user,
  $rabbitmq_astute_password  = $::fuel::params::rabbitmq_astute_password,

  $admin_network,
  $admin_network_cidr,
  $admin_network_size,
  $admin_network_first,
  $admin_network_last,
  $admin_network_netmask,
  $admin_network_mac,
  $admin_network_ip,
  $admin_network_gateway,

  $cobbler_host              = $::fuel::params::cobbler_host,
  $cobbler_url               = $::fuel::params::cobbler_url,
  $cobbler_user              = $::fuel::params::cobbler_user,
  $cobbler_password          = $::fuel::params::cobbler_password,

  $mco_pskey                 = $::fuel::params::mco_pskey,
  $mco_vhost                 = $::fuel::params::mco_vhost,
  $mco_host                  = $::fuel::params::mco_host,
  $mco_user                  = $::fuel::params::mco_user,
  $mco_password              = $::fuel::params::mco_password,
  $mco_connector             = $::fuel::params::mco_connector,

  $ntp_upstream              = $::fuel::params::ntp_upstream,
  $dns_upstream              = $::fuel::params::dns_upstream,
  $dns_domain                = $::fuel::params::dns_domain,

  $exclude_network           = $admin_network,
  $exclude_cidr              = $admin_network_cidr,

) inherits fuel::params {

  ensure_packages(['fuel-nailgun', 'python-psycopg2', 'crontabs', 'cronie-anacron',
    'uwsgi', 'uwsgi-plugin-common', 'uwsgi-plugin-python'])

  $services = [ 'assassind',
    'nailgun',
    'oswl_flavor_collectord',
    'oswl_image_collectord',
    'oswl_keystone_user_collectord',
    'oswl_tenant_collectord',
    'oswl_vm_collectord',
    'oswl_volume_collectord',
    'receiverd',
    'statsenderd',
  ]

  # FIXME(kozhukalov): fuel-nailgun package should provide nailgun group
  group { 'nailgun' :
    provider => "groupadd",
    ensure   => "present",
  }

  # FIXME(kozhukalov): fuel-nailgun package should provide nailgun user
  user { 'nailgun' :
    ensure  => "present",
    gid     => 'nailgun',
    home    => "/",
    shell   => "/bin/false",
    require => Group['nailgun'],
  }

  # FIXME(kozhukalov): fuel-nailgun package should provide
  # /etc/nailgun directory
  file { "/etc/nailgun":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  file { "/etc/logrotate.d/nailgun":
    content => template("fuel/logrotate.conf.erb"),
  }

  # FIXME(kozhukalov): fuel-nailgun package should provide
  # /var/log/nailgun directory
  file { "/var/log/nailgun":
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  # NOTE(eli): In order for plugins to be run on master node
  # without a need to hardcode full path, create a symlink
  # so Nailgun can set CWD during execution of plugin tasks.
  file {'/etc/fuel/plugins':
    ensure => link,
    target => '/var/www/nailgun/plugins',
  }

  file { "/etc/nailgun/settings.yaml":
    content => template("fuel/nailgun/settings.yaml.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => File["/etc/nailgun"],
    notify  => Service[$services],
  }

  exec { "nailgun_syncdb":
    command     => "/usr/bin/nailgun_syncdb",
    subscribe   => File["/etc/nailgun/settings.yaml"],
    tries       => 50,
    try_sleep   => 5,
    timeout     => 0,
  }

  exec { "nailgun_upload_fixtures":
    command     => '/usr/bin/nailgun_fixtures',
    refreshonly => true,
    subscribe   => File["/etc/nailgun/settings.yaml"],
    require     => Exec['nailgun_syncdb'],
    tries       => 50,
    try_sleep   => 5,
  }

  file { "/etc/cron.daily/capacity":
    content => template("fuel/nailgun/cron_daily_capacity.erb"),
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package['cronie-anacron']
  }

  cron { 'oswl_cleaner':
    ensure      => present,
    command     => 'oswl_cleaner',
    environment => [ 'MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin' ],
    user        => 'nailgun',
    hour        => '1',
    require     => Package['crontabs'],
  }

  service { 'crond':
    ensure => running,
    enable => true,
  }

  $fuel_key = $::generate_fuel_key

  if ($::physicalprocessorcount + 0) > 4  {
    $physicalprocessorcount = 8
  } else {
    $physicalprocessorcount = $::physicalprocessorcount * 2
  }

  $somaxconn = "4096"
  sysctl::value{ 'net.core.somaxconn': value => $somaxconn }

  file { '/etc/nailgun/uwsgi_nailgun.yaml':
    content => template('fuel/nailgun/uwsgi_nailgun.yaml.erb'),
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[['uwsgi', 'fuel-nailgun']],
  } ->

  file { '/var/lib/nailgun-uwsgi':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0644',
  } ->

  fuel::systemd { $services: }

}
