# this will wreak havoc on your system without --noop
# you have been warned ;)
node default {
  class { 'zabbix::frontend':
    ensure => present,
  }
}
