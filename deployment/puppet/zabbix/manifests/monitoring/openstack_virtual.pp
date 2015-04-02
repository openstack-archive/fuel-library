class zabbix::monitoring::openstack_virtual inherits zabbix::params {

  if $zabbix::params::host_name == $virtual_cluster_hostname {
    package {
      'python-sqlalchemy':
        ensure => present;
      'MySQL-python':
        ensure => present;
      'python-simplejson':
        ensure => present;
    }
    
    zabbix_host { $virtual_cluster_name:
      host    => $virtual_cluster_name,
      ip      => $host_ip,
      groups  => $host_groups,
      api     => $api_hash,
    }

    zabbix_template_link { "${virtual_cluster_name} Template OpenStack Cluster":
      host    => $virtual_cluster_name,
      template => 'Template OpenStack Cluster',
      api => $api_hash,
    }

    zabbix_template_link { "${virtual_cluster_name} Template App OpenStack Cinder API check":
      host     => $virtual_cluster_name,
      template => 'Template App OpenStack Cinder API check',
      api      => $api_hash,
    }

    zabbix_template_link { "${virtual_cluster_name} Template App OpenStack Glance API check":
      host     => $virtual_cluster_name,
      template => 'Template App OpenStack Glance API check',
      api      => $api_hash,
    }

    zabbix_template_link { "${virtual_cluster_name} Template App OpenStack Keystone API check":
      host     => $virtual_cluster_name,
      template => 'Template App OpenStack Keystone API check',
      api      => $api_hash,
    }

    zabbix_template_link { "${virtual_cluster_name} Template App OpenStack Nova API OSAPI check":
      host     => $virtual_cluster_name,
      template => 'Template App OpenStack Nova API OSAPI check',
      api      => $api_hash,
    }

    zabbix::agent::userparameter {
      'db.token.count.query':
        command => "/etc/zabbix/scripts/query_db.py token_count";
      'db.instance.error.query':
        command => "/etc/zabbix/scripts/query_db.py instance_error";
      'db.services.offline.nova.query':
        command => "/etc/zabbix/scripts/query_db.py services_offline_nova";
      'db.instance.count.query':
        command => "/etc/zabbix/scripts/query_db.py instance_count";
      'db.cpu.total.query':
        command => "/etc/zabbix/scripts/query_db.py cpu_total";
      'db.cpu.used.query':
        command => "/etc/zabbix/scripts/query_db.py cpu_used";
      'db.ram.total.query':
        command => "/etc/zabbix/scripts/query_db.py ram_total";
      'db.ram.used.query':
        command => "/etc/zabbix/scripts/query_db.py ram_used";
      'db.services.offline.cinder.query':
        command => "/etc/zabbix/scripts/query_db.py services_offline_cinder";
      'nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${nova_vip} 8774";
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${glance_vip} 9292";
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${keystone_vip} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${keystone_vip} 35357";
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${cinder_vip} 8776";
    }
    
  }
}
