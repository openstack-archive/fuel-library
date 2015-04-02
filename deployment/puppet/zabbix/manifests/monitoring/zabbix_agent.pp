class zabbix::monitoring::zabbix_agent inherits zabbix::params {
  $enabled = true

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix::agent::userparameter {
      'vfs.dev.discovery':
        ensure => 'present',
        command => '/etc/zabbix/scripts/vfs.dev.discovery.sh';
      'vfs.mdadm.discovery':
        ensure => 'present',
        command => '/etc/zabbix/scripts/vfs.mdadm.discovery.sh';
      'proc.vmstat':
        key => 'proc.vmstat[*]',
        command => 'grep \'$1\' /proc/vmstat | awk \'{print $$2}\'';
      'crm.node.check':
        key     => 'crm.node.check[*]',
        command => '/etc/zabbix/scripts/crm_node_check.sh $1';
    }

    #Linux
    zabbix_template_link { "${host_name} Template Fuel OS Linux":
      host => $host_name,
      template => 'Template Fuel OS Linux',
      api => $api_hash,
    }

    #Zabbix Agent
    zabbix_template_link { "${host_name} Template App Zabbix Agent":
      host => $host_name,
      template => 'Template App Zabbix Agent',
      api => $api_hash,
    }

  }

}
