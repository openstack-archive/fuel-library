class zabbix::monitoring::openstack_virtual_mon {

  include zabbix::params

  if $zabbix::params::host_name == $zabbix::params::openstack::virtual_cluster_hostname {
    package {
      'python-sqlalchemy':
        ensure => present;
      'MySQL-python':
        ensure => present;
      'python-simplejson':
        ensure => present;
    }
    
    zabbix_host { $zabbix::params::openstack::virtual_cluster_name:
      host    => $zabbix::params::openstack::virtual_cluster_name,
      ip      => $::internal_address,
      groups  => $zabbix::params::host_groups,
      api     => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::openstack::virtual_cluster_name Template OpenStack Cluster":
      host    => $zabbix::params::openstack::virtual_cluster_name,
      template => 'Template OpenStack Cluster',
      api => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::openstack::virtual_cluster_name Template App OpenStack Cinder API check":
      host     => $zabbix::params::openstack::virtual_cluster_name,
      template => 'Template App OpenStack Cinder API check',
      api      => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::openstack::virtual_cluster_name Template App OpenStack Glance API check":
      host     => $zabbix::params::openstack::virtual_cluster_name,
      template => 'Template App OpenStack Glance API check',
      api      => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::openstack::virtual_cluster_name Template App OpenStack Keystone API check":
      host     => $zabbix::params::openstack::virtual_cluster_name,
      template => 'Template App OpenStack Keystone API check',
      api      => $zabbix::params::api_hash,
    }

    zabbix_template_link { "$zabbix::params::openstack::virtual_cluster_name Template App OpenStack Nova API OSAPI check":
      host     => $zabbix::params::openstack::virtual_cluster_name,
      template => 'Template App OpenStack Nova API OSAPI check',
      api      => $zabbix::params::api_hash,
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
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::zabbix::params::openstack::nova_vip} 8774";
      'glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${::zabbix::params::openstack::glance_vip} 9292";
      'keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${::zabbix::params::openstack::keystone_vip} 5000";
      'keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${::zabbix::params::openstack::keystone_vip} 35357";
      'cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${::zabbix::params::openstack::cinder_vip} 8776";
    }
    
  }
}
