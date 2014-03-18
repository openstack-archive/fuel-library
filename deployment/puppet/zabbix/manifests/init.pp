class zabbix {
  include zabbix::params
  if $::zabbix::params::enabled {
    if $::zabbix::params::server {
      class {'zabbix::server': }
      class {'zabbix::server::config': 
        require => Class['zabbix::server'],
      }
    }
  }
}
