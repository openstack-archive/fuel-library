class zabbix::monitoring::ceilometer_compute_mon {

  include zabbix::params

  #Ceilometer
  if defined(Class['Ceilometer::Agent::Compute']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Ceilometer Compute":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Ceilometer Compute',
      api => $zabbix::params::api_hash,
    }
  }
}
