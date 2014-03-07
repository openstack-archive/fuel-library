class zabbix::monitoring::horizon_mon {

  include zabbix::params

  #Horizon
  if defined(Class['horizon']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Horizon":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Horizon',
      api => $zabbix::params::api_hash,
    }
  }
}
