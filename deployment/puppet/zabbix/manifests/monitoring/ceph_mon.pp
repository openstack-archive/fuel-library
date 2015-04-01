class zabbix::monitoring::ceph_mon {

  include zabbix::params

  if hiera('node_role') == 'ceph-osd' {
    zabbix_template_link { "${zabbix::params::host_name} Template App OpenStack Ceph":
      host     => $zabbix::params::host_name,
      template => 'Template App OpenStack Ceph',
      api      => $zabbix::params::api_hash,
    }
    zabbix::agent::userparameter {
      'ceph_health':
        key     => 'ceph.health',
        command => '/etc/zabbix/scripts/ceph_health.sh'
    }
  }
}
