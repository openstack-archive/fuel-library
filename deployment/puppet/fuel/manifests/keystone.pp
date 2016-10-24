class fuel::keystone (
  $host              = $::fuel::params::keystone_host,
  $port              = $::fuel::params::keystone_port,
  $admin_port        = $::fuel::params::keystone_admin_port,
  $keystone_domain   = $::fuel::params::keystone_domain,

  $ssl               = $::fuel::params::ssl,

  $vhost_limit_request_field_size = $::fuel::params::vhost_limit_request_field_size,

  $db_engine         = $::fuel::params::db_engine,
  $db_host           = $::fuel::params::db_host,
  $db_port           = $::fuel::params::db_port,
  $db_name           = $::fuel::params::keystone_db_name,
  $db_user           = $::fuel::params::keystone_db_user,
  $db_password       = $::fuel::params::keystone_db_password,

  $admin_token       = $::fuel::params::keystone_admin_token,
  $token_expiration  = $::fuel::params::keystone_token_expiration,

  $admin_user        = $::fuel::params::keystone_admin_user,
  $admin_password    = $::fuel::params::keystone_admin_password,

  $monitord_user     = $::fuel::params::keystone_monitord_user,
  $monitord_password = $::fuel::params::keystone_monitord_password,

  $nailgun_user      = $::fuel::params::keystone_nailgun_user,
  $nailgun_password  = $::fuel::params::keystone_nailgun_password,

  $ostf_user         = $::fuel::params::keystone_ostf_user,
  $ostf_password     = $::fuel::params::keystone_ostf_password,

  ) inherits fuel::params {

  ensure_packages(['crontabs', 'rubygem-thread_safe'])

  file { ['/etc/httpd/', '/etc/httpd/conf.ports.d/']: ensure  => directory }
  ->
  class {'::apache':
    server_signature => 'Off',
    trace_enable     => 'Off',
    purge_configs    => false,
    purge_vhost_dir  => false,
    default_vhost    => false,
    ports_file       => '/etc/httpd/conf.ports.d/keystone.conf',
    conf_template    => 'fuel/httpd.conf.erb',
  }

  class { '::keystone':
    # (TODO iberezovskiy): Set 'enable_bootstrap' to true when MOS packages will
    # be updated and 'keystone-manage bootstrap' command will be available
    enable_bootstrap    => false,
    admin_token         => $admin_token,
    admin_password      => $admin_password,
    catalog_type        => 'sql',
    database_connection => "${db_engine}://${db_user}:${db_password}@${db_host}:${db_port}/${db_name}",
    token_expiration    => $token_expiration,
    token_provider      => 'keystone.token.providers.uuid.Provider',
    enable_fernet_setup => false,
    default_domain      => $keystone_domain,
    service_name        => 'httpd',
    use_syslog          => true,
  }
  class { 'keystone::wsgi::apache':
    public_port           => $port,
    admin_port            => $admin_port,
    ssl                   => $ssl,
    priority              => '05',
    threads               => 3,
    workers               => min($::processorcount, 6),
    vhost_custom_fragment => $vhost_limit_request_field_size,
    access_log_format     => 'forwarded',
   }

  # Ensure that keystone_paste_ini file includes "admin_token_auth" filter
  # so the Puppet keystone types are able to use the admin token.
  # It will be removed by the next task.

  #FIXME(dilyin): This should be rewritten using ini_subsettings
  # or some other way
  $keystone_paste_ini = '/etc/keystone/keystone-paste.ini'

  exec { 'add_admin_token_auth_middleware':
    path    => ['/bin', '/usr/bin'],
    command => "sed -i 's/\\( token_auth \\)/\\1admin_token_auth /' ${keystone_paste_ini}",
    unless  => "fgrep -q ' admin_token_auth' ${keystone_paste_ini}",
    require => Package['keystone'],
  }

  Exec['add_admin_token_auth_middleware'] ->
  Exec <| title == 'keystone-manage db_sync' |> ->

  # FIXME(kozhukalov): Remove this hack and use enable_bootstrap instead
  # once patch is merged and test envs are updated with the ISO
  # that contains Mitaka keystone rpm package.
  Exec <| title == 'keystone-manage bootstrap' |> {
    command => "keystone-manage bootstrap --bootstrap-password ${admin_token} || true"
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
    domain  => $keystone_domain,
  }

  keystone_tenant { 'services':
    ensure      => present,
    enabled     => 'True',
    description => 'fuel services tenant',
    domain      => $keystone_domain,
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
    domain           => $keystone_domain,
  }

  # assigning role 'admin' to user 'admin' in tenant 'admin'
  keystone_user_role { "${admin_user}@admin":
    ensure         => present,
    roles          => ['admin'],
    user_domain    => $keystone_domain,
    project_domain => $keystone_domain,
  }

  # Monitord user
  keystone_user { $monitord_user :
    ensure   => present,
    password => $monitord_password,
    enabled  => 'True',
    email    => 'monitord@localhost',
    domain   => $keystone_domain,
  }

  keystone_user_role { "${monitord_user}@services":
    ensure         => present,
    roles          => ['monitoring'],
    user_domain    => $keystone_domain,
    project_domain => $keystone_domain,
  }

  # Keystone Endpoint
  class { 'keystone::endpoint':
    public_url   => "http://${host}:${port}",
    admin_url    => "http://${host}:${admin_port}",
    internal_url => "http://${host}:${port}",
  }

  # Nailgun
  class { 'fuel::auth':
    auth_name       => $nailgun_user,
    password        => $nailgun_password,
    address         => $host,
    keystone_domain => $keystone_domain,
  }

  # OSTF
  class { 'fuel::ostf::auth':
    auth_name       => $ostf_user,
    password        => $ostf_password,
    address         => $host,
    keystone_domain => $keystone_domain,
  }

  service { 'crond':
    ensure => running,
    enable => true,
  }

  # Flush expired tokens
  cron { 'keystone-flush-token':
    ensure      => present,
    command     => 'keystone-manage token_flush',
    environment => [ 'MAILTO=""', 'PATH=/bin:/usr/bin:/usr/sbin' ],
    user        => 'keystone',
    hour        => '1',
    require     => [ Package['crontabs'], Package['keystone'] ],
  }

}
