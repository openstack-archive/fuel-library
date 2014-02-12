node default {
  zabbix::agent::param { 'foo.bar.baz':
    ensure => present
  }
}
