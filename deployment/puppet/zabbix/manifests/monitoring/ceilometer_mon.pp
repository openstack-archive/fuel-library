class zabbix::monitoring::ceilometer_mon {

  include zabbix::params

  #Ceilometer
  if defined(Class['Ceilometer']) and defined(Class['Openstack::Controller']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Ceilometer":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Ceilometer',
      api => $zabbix::params::api_hash,
    }
  }
}
