class openstack_tasks::openstack_network::sync_db {
  notice('MODULAR: openstack_network/sync_db.pp')

  include neutron::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['neutron-db-sync']
}
