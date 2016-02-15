class fuel::keystone (
  $host              = $::fuel::params::keystone_host,
  $port              = $::fuel::params::keystone_port,
  $admin_port        = $::fuel::params::keystone_admin_port,

  $db_engine         = $::fuel::params::db_engine,
  $db_host           = $::fuel::params::db_host,
  $db_port           = $::fuel::params::db_port,
  $db_name           = $::fuel::params::keystone_db_name,
  $db_user           = $::fuel::params::keystone_db_user,
  $db_password       = $::fuel::params::keystone_db_password,

  $admin_token       = $::fuel::params::keystone_admin_token,

  $admin_user        = $::fuel::params::keystone_admin_user,
  $admin_password    = $::fuel::params::keystone_admin_password,

  $monitord_user     = $::fuel::params::keystone_monitord_user,
  $monitord_password = $::fuel::params::keystone_monitord_password,

  $nailgun_user      = $::fuel::params::keystone_nailgun_user,
  $nailgun_password  = $::fuel::params::keystone_nailgun_password,

  $ostf_user         = $::fuel::params::keystone_ostf_user,
  $ostf_password     = $::fuel::params::keystone_ostf_password,

  $auth_version      = $::fuel::params::keystone_auth_version,
  ) inherits fuel::params {

  ensure_packages([
    'crontabs',
    'os-client-config',
    'python-tablib',
    'python-unicodecsv',
    'rubygem-thread_safe',
  ])

  class { '::keystone':
    admin_token         => $admin_token,
    catalog_type        => 'sql',
    database_connection => "${db_engine}://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}",
    token_expiration    => 86400,
    token_provider      => 'keystone.token.providers.uuid.Provider',
  }

  #FIXME(mattymo): We should enable db_sync on every run inside keystone,
  #but this is related to a larger scope fix for concurrent deployment of
  #secondary controllers.
  Exec <| title == 'keystone-manage db_sync' |> {
    refreshonly => false,
  }

  # Creating tenants
  keystone_tenant { 'admin':
    ensure  => present,
    enabled => 'True',
  }

  keystone_tenant { 'services':
    ensure      => present,
    enabled     => 'True',
    description => 'fuel services tenant',
  }

  # Creating roles
  keystone_role { 'admin':
    ensure => present,
  }

  keystone_role { 'monitoring':
    ensure => present,
  }

  # Creating users

  # Admin user
  keystone_user { $admin_user :
    ensure           => present,
    password         => $admin_password,
    enabled          => 'True',
    replace_password => false,
  }

  # assigning role 'admin' to user 'admin' in tenant 'admin'
  keystone_user_role { "${admin_user}@admin":
    ensure => present,
    roles  => ['admin'],
  }

  # Monitord user
  keystone_user { $monitord_user :
    ensure   => present,
    password => $monitord_password,
    enabled  => 'True',
    email    => 'monitord@localhost',
  }

  keystone_user_role { "${monitord_user}@services":
    ensure => present,
    roles  => ['monitoring'],
  }

  # Keystone Endpoint
  class { 'keystone::endpoint':
    public_url   => "http://${host}:${port}/${auth_version}",
    admin_url    => "http://${host}:${admin_port}/${auth_version}",
    internal_url => "http://${host}:${port}/${auth_version}",
  }

  # Nailgun
  class { 'fuel::auth':
    auth_name => $nailgun_user,
    password  => $nailgun_password,
    address   => $host,
  }

  # OSTF
  class { 'fuel::ostf::auth':
    auth_name => $ostf_user,
    password  => $ostf_password,
    address   => $host,
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
