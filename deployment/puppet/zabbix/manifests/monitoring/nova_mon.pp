class zabbix::monitoring::nova_mon {

  include zabbix::params

  # Nova (controller)
  if defined_in_state(Class['openstack::controller']) {

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova API":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova API',
      api => $zabbix::monitoring::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova API OSAPI":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova API OSAPI',
      api => $zabbix::monitoring::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova API OSAPI check":
      host    => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova API OSAPI check',
      api => $zabbix::monitoring::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova API EC2":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova API EC2',
      api => $zabbix::monitoring::api_hash,
    }

    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova Cert":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova Cert',
      api => $zabbix::monitoring::api_hash,
    }

    zabbix::agent::userparameter {
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::internal_address} 8774";
    }

    if ! $::fuel_settings['quantum'] {
      zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova Network":
        host => $zabbix::params::host_name,
        template => 'Template App OpenStack Nova Network',
        api => $zabbix::monitoring::api_hash,
      }
    }
  }

  #Nova (compute)
  if defined_in_state(Class['openstack::compute']) {

    if ! $::fuel_settings['quantum'] {
      zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova API Metadata":
        host => $zabbix::params::host_name,
        template => 'Template App OpenStack Nova API Metadata',
        api => $zabbix::monitoring::api_hash,
      }
    }
  }

  if defined_in_state(Class['nova::consoleauth']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova ConsoleAuth":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova ConsoleAuth',
      api => $zabbix::monitoring::api_hash,
    }
  }

  if defined_in_state(Class['nova::scheduler']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova Scheduler":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova Scheduler',
      api => $zabbix::monitoring::api_hash,
    }
  }

  #Nova compute
  if defined_in_state(Class['nova::compute']) {
    zabbix_template_link { "$zabbix::params::host_name Template App OpenStack Nova Compute":
      host => $zabbix::params::host_name,
      template => 'Template App OpenStack Nova Compute',
      api => $zabbix::monitoring::api_hash,
    }
  }

  #Libvirt
  if defined_in_state(Class['nova::compute::libvirt']) {
    zabbix_template_link { "$::fqdn Template App OpenStack Libvirt":
      host => $::fqdn,
      template => 'Template App OpenStack Libvirt',
      api => $zabbix::monitoring::api_hash,
    }
  }
}
