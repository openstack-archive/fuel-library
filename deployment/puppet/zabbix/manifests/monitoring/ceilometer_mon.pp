class zabbix::monitoring::ceilometer_mon {

  include zabbix::params

  #Ceilometer
  if defined_in_state(Class['Ceilometer']) and defined_in_state(Class['Openstack::Controller']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Ceilometer":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Ceilometer',
      api => $zabbix::monitoring::api_hash,
    }
  }
}
