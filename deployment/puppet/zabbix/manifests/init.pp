class zabbix {
  include zabbix::params
  if $::zabbix::params::enabled {
    if $::zabbix::params::server {
      class {'zabbix::server': 
        before => Class['zabbix::monitoring']
      }
      class {'zabbix::server::config': 
        require => Class['zabbix::server'],
        before  => Class['zabbix::monitoring']
      }
    }
    class {'zabbix::monitoring': }
  }
}
