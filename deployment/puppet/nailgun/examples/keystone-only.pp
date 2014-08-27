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

    keystone_tenant { 'admin' :
      enabled => 'True',
      ensure  => present
    }

    keystone_role {'admin' :
      ensure => present
    }

    keystone_user { 'admin':
      password => $::fuel_settings['FUEL_ACCESS']['password'],
      ensure   => present,
      enabled  => 'True',
      tenant   => 'admin'
    }

    keystone_user_role { 'admin@admin':
      roles  => ['admin'],
      ensure => present
    }
  }
  'docker-build': {
  }
}
