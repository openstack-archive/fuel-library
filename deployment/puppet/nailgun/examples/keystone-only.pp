$fuel_settings = parseyaml($astute_settings_yaml)
$fuel_version = parseyaml($fuel_version_yaml)

if is_hash($::fuel_version) and $::fuel_version['VERSION'] and $::fuel_version['VERSION']['production'] {
    $production = $::fuel_version['VERSION']['production']
}
else {
    $production = 'prod'
}

package { 'python-psycopg2':
  ensure => installed,
}

case $production {
  'prod', 'docker': {
    class { 'keystone':
      admin_token     => $::fuel_settings['keystone']['admin_token'],
      catalog_type    => 'sql',
      sql_connection => "postgresql://${::fuel_settings['postgres']['keystone_user']}:${::fuel_settings['postgres']['keystone_password']}@${::fuel_settings['ADMIN_NETWORK']['ipaddress']}/${::fuel_settings['postgres']['keystone_dbname']}",
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
      ensure   => present,
      password => $::fuel_settings['FUEL_ACCESS']['password'],
      enabled  => 'True',
      tenant   => 'admin',
    }

    keystone_user_role { 'admin@admin':
      ensure => present,
      roles  => ['admin'],
    }

    # Keystone Endpoint
    class { 'keystone::endpoint':
      public_address   => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
      admin_address    => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
      internal_address => $::fuel_settings['ADMIN_NETWORK']['ipaddress'],
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

    # Increase token expiratin to 24h
    keystone_config {
      'token/expiration': value => 86400;
    }

    package { 'crontabs':
      ensure => latest,
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
