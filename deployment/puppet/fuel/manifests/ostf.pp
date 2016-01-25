class fuel::ostf(
  $dbuser               = $::fuel::params::ostf_db_user,
  $dbpass               = $::fuel::params::ostf_db_password,
  $dbname               = $::fuel::params::ostf_db_name,
  $dbhost               = $::fuel::params::db_host,
  $dbport               = $::fuel::params::db_port,
  $nailgun_host         = $::fuel::params::nailgun_host,
  $nailgun_port         = $::fuel::params::nailgun_port,
  $dbengine             = 'postgresql+psycopg2',
  $host                 = $::fuel::params::ostf_host,
  $port                 = $::fuel::params::ostf_port,
  $logfile              = '/var/log/ostf.log',
  $keystone_host        = $::fuel::params::keystone_host,
  $keystone_port        = $::fuel::params::keystone_admin_port,
  $keystone_ostf_user   = $::fuel::params::keystone_ostf_user,
  $keystone_ostf_pass   = $::fuel::params::keystone_ostf_password,
  $auth_enable          = 'True',
  ) inherits fuel::params {

  ensure_packages(['libevent-devel', 'openssl-devel', 'fuel-ostf', 'python-psycopg2'])

  exec {'ostf-init':
    command => "/usr/bin/ostf-server \
    --after-initialization-environment-hook",
    tries     => 50,
    try_sleep => 5,
  }

  Package['fuel-ostf'] -> Exec['ostf-init']
  File['/etc/ostf/ostf.conf'] -> Exec['ostf-init']

  file { '/etc/ostf/':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  file { '/etc/ostf/ostf.conf':
    owner   => 'root',
    group   => 'root',
    content => template('fuel/ostf.conf.erb'),
  }

  file { '/var/log/ostf':
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }
}
