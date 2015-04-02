class zabbix::monitoring::memcached inherits zabbix::params {
  $enabled = ($role in ['controller', 'primary-controller'])

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App Memcache":
      host => $host_name,
      template => 'Template App Memcache',
      api => $api_hash,
    }

    file { '/etc/zabbix/scripts/check_memcached.sh':
      mode  => '0755',
      ensure    => present,
      content   => template('zabbix/check_memcached.sh.erb'),
    }

    zabbix::agent::userparameter {
      'memcache':
        key     => 'memcache[*]',
        command => '/etc/zabbix/scripts/check_memcached.sh $1',
    }
  }
}
