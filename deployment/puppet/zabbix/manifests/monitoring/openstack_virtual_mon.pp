class zabbix::monitoring::openstack_virtual_mon {

  include zabbix::params

  $roles = node_roles($::fuel_settings['nodes'], $::fuel_settings['uid'])

  if (($::fuel_settings["deployment_mode"] == "multinode") and member($roles, 'controller')) or
    member($roles, 'primary-controller') {

    zabbix_host { $zabbix::params::openstack::virtual_cluster_name:
      host    => $zabbix::params::openstack::virtual_cluster_name,
      ip      => $zabbix::monitoring::server_vip,
      port    => $zabbix::monitoring::ports['agent'],
      groups  => $zabbix::params::host_groups_base,
      api     => $zabbix::monitoring::api_hash,
    }
    zabbix_template_link { "$zabbix::params::openstack::virtual_cluster_name Template OpenStack Cluster":
      host    => $zabbix::params::openstack::virtual_cluster_name,
      template => 'Template OpenStack Cluster',
      api => $zabbix::monitoring::api_hash,
    }
  }

  if defined_in_state(Class['openstack::controller']) {
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
      'vip.nova.api.status':
        command => "/etc/zabbix/scripts/check_api.py nova_os http ${::zabbix::params::openstack::nova_vip} 8774";
      'vip.glance.api.status':
        command => "/etc/zabbix/scripts/check_api.py glance http ${::zabbix::params::openstack::glance_vip} 9292";
      'vip.keystone.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone http ${::zabbix::params::openstack::keystone_vip} 5000";
      'vip.keystone.service.api.status':
        command => "/etc/zabbix/scripts/check_api.py keystone_service http ${::zabbix::params::openstack::keystone_vip} 35357";
      'vip.cinder.api.status':
        command => "/etc/zabbix/scripts/check_api.py cinder http ${::zabbix::params::openstack::cinder_vip} 8776";
    }
  }
}
