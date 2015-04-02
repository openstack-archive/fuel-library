class zabbix::monitoring::ceph inherits zabbix::params {
  $enabled = ($role == 'ceph-osd')

  if $enabled {
    notice("Ceilometer monitoring auto-registration: '${name}'")

    zabbix_template_link { "${host_name} Template App OpenStack Ceph":
      host     => $host_name,
      template => 'Template App OpenStack Ceph',
      api      => $api_hash,
    }
    zabbix::agent::userparameter {
      'ceph_health':
        key     => 'ceph.health',
        command => '/etc/zabbix/scripts/ceph_health.sh'
    }
  }
}
