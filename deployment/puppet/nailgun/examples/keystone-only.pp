$fuel_settings = parseyaml($astute_settings_yaml)

if $::fuel_settings['PRODUCTION'] {
    $production = $::fuel_settings['PRODUCTION']
}
else {
    $production = 'docker'
}

package { 'python-psycopg2':
  ensure => installed,
}

$auth_version = "v2.0"

case $production {
  'prod', 'docker': {

    class {'docker::container': }

    class { 'keystone':
      admin_token      => $::fuel_settings['keystone']['admin_token'],
      catalog_type     => 'sql',
      database_connection   => "postgresql://${::fuel_settings['postgres']['keystone_user']}:${::fuel_settings['postgres']['keystone_password']}@${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/${::fuel_settings['postgres']['keystone_dbname']}",
      token_expiration => 86400,
      token_provider   => 'keystone.token.providers.uuid.Provider',
    }

    #FIXME(mattymo): We should enable db_sync on every run inside keystone,
    #but this is related to a larger scope fix for concurrent deployment of
    #secondary controllers.
    Exec <| title == 'keystone-manage db_sync' |> {
      refreshonly => false,
    }

    Exec["add_admin_token_auth_middleware"] -> Keystone_tenant <||> -> Exec["remove_admin_token_auth_middleware"]
    Exec["add_admin_token_auth_middleware"] -> Keystone_role <||> -> Exec["remove_admin_token_auth_middleware"]
    Exec["add_admin_token_auth_middleware"] -> Keystone_user <||> -> Exec["remove_admin_token_auth_middleware"]
    Exec["add_admin_token_auth_middleware"] -> Keystone_user_role <||> -> Exec["remove_admin_token_auth_middleware"]

    # Get paste.ini source
    $keystone_paste_ini = $::keystone::params::paste_config ? {
      undef   => '/etc/keystone/keystone-paste.ini',
      default => $::keystone::params::paste_config,
    }

    # Temporary add admin_token_auth middleware from public/admin/v3 pipelines
    exec { 'add_admin_token_auth_middleware':
      path    => ['/bin', '/usr/bin'],
      command => "sed -i.dist 's/ token_auth / token_auth admin_token_auth /' ${keystone_paste_ini}",
      unless  => "fgrep -q ' admin_token_auth' ${keystone_paste_ini}",
    }

    # Remove admin_token_auth middleware from public/admin/v3 pipelines
    exec { 'remove_admin_token_auth_middleware':
      path    => ['/bin', '/usr/bin'],
      command => "mv ${keystone_paste_ini}.dist ${keystone_paste_ini}",
      onlyif  => "test -f ${keystone_paste_ini}.dist",
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
      password        => $::fuel_settings['FUEL_ACCESS']['password'],
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

    keystone_user { $::fuel_settings['keystone']['monitord_user']:
      ensure   => present,
      password => $::fuel_settings['keystone']['monitord_password'],
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
      public_url   => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:5000/${auth_version}",
      admin_url    => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:35357/${auth_version}",
      internal_url => "http://${::fuel_settings['ADMIN_NETWORK']['ipaddress']}:5000/${auth_version}",
    }

    # Nailgun
    class { 'nailgun::auth':
      auth_name => $::fuel_settings['keystone']['nailgun_user'],
      password  => $::fuel_settings['keystone']['nailgun_password'],
      address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    }

    # OSTF
    class { 'nailgun::ostf::auth':
      auth_name => $::fuel_settings['keystone']['ostf_user'],
      password  => $::fuel_settings['keystone']['ostf_password'],
      address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
    }

    # Tuningbox
    class { 'nailgun::tuningbox::auth':
      auth_name => $::fuel_settings['keystone']['tuningbox_user'],
      password  => $::fuel_settings['keystone']['tuningbox_password'],
      address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
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
  'docker-build': {
  }
}
