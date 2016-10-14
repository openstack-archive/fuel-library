class openstack_tasks::sahara::sync_db {
  notice('MODULAR: sahara/sync_db.pp')

  include sahara::db::sync

  exec { '/bin/true': }
  Exec['/bin/true'] ~> Exec['sahara-dbmanage']

}

