class zabbix::monitoring::glance_mon {

  include zabbix::params

  #Glance
  if defined(Class['glance::api']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Glance API":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Glance API',
      api => $zabbix::params::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Glance API check":
      host    => $zabbix::params::host_name,
      template => 'Template App OpenStack Glance API check',
      api => $zabbix::params::api_hash,
    }
    zabbix::agent::userparameter {
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${::internal_address} 9292";
    }
  }

  if defined(Class['glance::registry']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Glance Registry":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Glance Registry',
      api => $zabbix::params::api_hash,
    }
  }
}
