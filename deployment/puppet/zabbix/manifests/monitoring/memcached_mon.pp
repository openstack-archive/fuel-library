class zabbix::monitoring::memcached_mon {

  include zabbix::params

  if defined(Class['memcached']) {
    zabbix_template_link { "$zabbix::params::host_name Template App Memcache":
      host => $zabbix::params::host_name,
      template => 'Template App Memcache',
      api => $zabbix::params::api_hash,
    }
    $nodes_hash = $::fuel_settings['nodes']
    $node = filter_nodes($nodes_hash,'name',$::hostname)
    $internal_address = $node[0]['internal_address']

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
