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
      admin_token     => 'ADMIN',
      catalog_type    => 'sql',
      sql_connection => 'postgresql://' + $::fuel_setting['postgres']['keystone_user'] + ':' + $::fuel_setting['postgres']['keystone_password'] + '@' + $::fuel_settings['ADMIN_NETWORK']['ipaddress'] + '/' + $::fuel_setting['postgres']['keystone_dbname'],
    }

    keystone_tenant { 'admin' :
      enabled => 'True',
      ensure  => present
    }

    keystone_role {'admin' :
      ensure => present
    }

    keystone_user { 'admin':
      password => $::fuel_setting['FUEL_ACCESS']['password'],
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
