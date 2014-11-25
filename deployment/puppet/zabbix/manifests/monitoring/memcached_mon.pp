class zabbix::monitoring::memcached_mon {

  include zabbix::params

  if defined_in_state(Class['memcached']) {
    zabbix_template_link { "$zabbix::params::host_name Template App Memcache":
      host => $zabbix::params::host_name,
      template => 'Template App Memcache',
      api => $zabbix::monitoring::api_hash,
    }
    zabbix::agent::userparameter {
      'memcache':
        key     => 'memcache[*]',
        command => "/bin/echo -e \"stats\\nquit\" | nc ${zabbix::params::host_ip} 11211 | grep \"STAT \$1 \" | awk \'{print \$\$3}\'"
    }
  }
}
