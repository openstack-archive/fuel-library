class zabbix::monitoring::memcached_mon {

  include zabbix::params

  if defined(Class['memcached']) {
    zabbix_template_link { "$zabbix::params::host_name Template App Memcache":
      host => $zabbix::params::host_name,
      template => 'Template App Memcache',
      api => $zabbix::params::api_hash,
    }
    zabbix::agent::userparameter {
      'memcache':
        key     => 'memcache[*]',
        command => 'echo -e "stats\nquit" | nc 127.0.0.1 11211 | grep "STAT $1 " | awk \'{print $$3}\''
    }
  }
}
