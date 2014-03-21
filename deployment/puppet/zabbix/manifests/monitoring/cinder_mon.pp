class zabbix::monitoring::cinder_mon {

  include zabbix::params

  #Cinder
  if defined(Class['cinder::api']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Cinder API":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Cinder API',
      api => $zabbix::params::api_hash,
    }
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Cinder API check":
      host    => $zabbix::params::host_name,
      template => 'Template App OpenStack Cinder API check',
      api => $zabbix::params::api_hash,
    }
    zabbix::agent::userparameter {
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${::internal_address} 8776";
    }
  }

  if defined(Class['cinder::scheduler']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Cinder Scheduler":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Cinder Scheduler',
      api => $zabbix::params::api_hash,
    }
  }

  if defined(Class['cinder::volume']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Cinder Volume":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Cinder Volume',
      api => $zabbix::params::api_hash,
    }
  }
}
