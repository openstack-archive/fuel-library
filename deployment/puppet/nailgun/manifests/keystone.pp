class nailgun::keystone(
  $db_name          = $::nailgun::params::keystone_db_name,
  $db_user          = $::nailgun::params::keystone_db_user,
  $db_password      = $::nailgun::params::keystone_db_password,
  $db_address       = $::nailgun::params::keystone_db_address,
  $db_port          = $::nailgun::params::keystone_db_port,
  $auth_version     = $::nailgun::params::keystone_auth_verison,
  $catalog_type     = 'sql',
  $token_expiration = 86400,
  $public_baseurl,
  $admin_baseurl,
  $internal_baseurl,
  $auth_address,
  $admin_token,
  $admin_password,
  $monit_user,
  $monit_password,
  $nailgun_user,
  $nailgun_password,
  $ostf_user,
  $ostf_password,
  ) inherits nailgun::params {

  package { 'python-psycopg2':
    ensure => installed,
  }

  class { '::keystone':
    admin_token      => $admin_token,
    catalog_type     => 'sql',
    database_connection   => "postgresql://${db_user}:${db_password}@${db_address}:${db_port}/${db_name}",
    token_expiration => $token_expiration,
    token_provider   => 'keystone.token.providers.uuid.Provider',
  }

  #FIXME(mattymo): We should enable db_sync on every run inside keystone,
  #but this is related to a larger scope fix for concurrent deployment of
  #secondary controllers.
  Exec <| title == 'keystone-manage db_sync' |> {
    refreshonly => false,
  }

  # Admin user
  keystone_tenant { 'admin':
    ensure  => present,
    enabled => 'True',
  }

  keystone_tenant { 'services':
    ensure      => present,
    enabled     => 'True',
    description => 'fuel services tenant',
  }

  keystone_role { 'admin':
    ensure => present,
  }

  keystone_user { 'admin':
    ensure          => present,
    password        => $admin_password,
    enabled         => 'True',
    tenant          => 'admin',
    replace_password => false,
  }

  keystone_user_role { 'admin@admin':
    ensure => present,
    roles  => ['admin'],
  }

  # Monitord user
  keystone_role { 'monitoring':
    ensure => present,
  }

  keystone_user { $monit_user:
    ensure   => present,
    password => $monit_password,
    enabled  => 'True',
    email    => 'monitord@localhost',
    tenant   => 'services',
  }

  keystone_user_role { 'monitord@services':
    ensure => present,
    roles  => ['monitoring'],
  }

  # Keystone Endpoint
  class { 'keystone::endpoint':
    public_url   => "${public_baseurl}/${auth_version}",
    admin_url    => "${admin_baseurl}/${auth_version}",
    internal_url => "${internal_baseurl}/${auth_version}",
  }

  # Nailgun
  class { 'nailgun::auth':
    auth_name => $nailgun_user,
    password  => $nailgun_password,
    address   => $auth_address,
  }

  # OSTF
  class { 'nailgun::ostf::auth':
    auth_name => $ostf_user,
    password  => $ostf_password,
    address   => $auth_address,
  }

  package { 'crontabs':
    ensure => latest,
  }

  service { 'crond':
    ensure => running,
    enable => true,
  }

  # Flush expired tokens
  cron { 'keystone-flush-token':
    ensure      => present,
    command     => 'keystone-manage token_flush',
    environment => 'PATH=/bin:/usr/bin:/usr/sbin',
    user        => 'root',
    hour        => '1',
    require     => Package['crontabs'],
  }

}
