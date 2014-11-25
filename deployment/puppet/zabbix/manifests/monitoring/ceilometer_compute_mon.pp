class zabbix::monitoring::ceilometer_compute_mon {

  include zabbix::params

  #Ceilometer
  if defined_in_state(Class['Ceilometer::Agent::Compute']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Ceilometer Compute":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Ceilometer Compute',
      api => $zabbix::monitoring::api_hash,
    }
  }
}
